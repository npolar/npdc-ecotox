#!/usr/bin/env ruby
# Convert from the incoming ecotox Excel files to the new ecotox database
# Fetch Excel files from leser, reads them and moves them to ferdige_filer
#
# Author: srldl
#
# Requirements:
#
########################################

require '../config'
require '../server'
require 'net/http'
require 'net/ssh'
require 'net/scp'
require 'time'
require 'date'
require 'json'
require 'oci8'
require 'digest'
require 'net-ldap'
require 'rmagick'
require 'simple-spreadsheet'
require 'securerandom'
require 'fileutils'

module Couch

  class ReadExcel

    #Set server
    host = Couch::Config::HOST3
    port = Couch::Config::PORT3
    user = Couch::Config::USER3
    password = Couch::Config::PASSWORD3
    auth = Couch::Config::AUTH3

    #Set server
  #  host2 = Couch::Config::HOST4
  #  port2 = Couch::Config::PORT4
  #  user2 = Couch::Config::USER4
  #  password2 = Couch::Config::PASSWORD4
  #  auth2 = Couch::Config::AUTH4

   #rightsholder field
   def self.rightsholder(inp)
     case inp
     when "NPI, NTNU, NMBU"
       inp = "NPI,NTNU,NMBU"
     when "NPI, NMBU"
       inp = "NPI,NMBU"
     when  "NPI, Örebro University"
       inp = "NPI, Örebro"
     when "NPI,Univ of Windsor"
       inp = "NPI, Univ of Windsor"
     else
       inp
     end
     return  inp
   end

    #matrix field
    def self.matrix(inp)
      if (inp != nil && inp.length > 0) then inp.strip! end #remove trailing blanks
      case inp
      when "blood cells"
        inp = "blood cell"
      when "blood"
        inp = "whole blood"
      when "Blood"
        inp ="whole blood"
      when "adipose tissue"
        inp ="subcutaneous fat"
      when "biopsy"
        inp ="biopsy skin"
      when "adrenal"
        inp = "adrenal gland"
      else
        inp
      end
      return inp
    end



     #<loq everything detectable, but not quantificated
     #n.d. everything between zero and loq
    def self.wet_weight(inp)
      case inp
      when "n.q"
        inp = "<loq"
      when "na"
        inp = "n.a."
      when "n.a"
        inp = "n.a."
      when "n.a.n.a."
        inp = "n.a."
      when "n.d"
        inp = "n.d."
      when "0"
        inp = "n.d."
      when "loq"
        inp = "<loq"
      when "LOQ"
        inp = "<loq"
      when "LOD"
        inp = "n.d"
      when "lod"
        inp = "<loq"
      else
        inp
      end
      return inp
    end

    def self.species(inp)
      if (inp != nil && inp.length > 0)
        case inp.downcase.strip!
        when "laurs hyperboreus"
          inp= "larus hyperboreus"
        when "larus maritimus"
          inp = "larus marinus"
        when "eukroma hamata"
          inp = "eukrohnia hamata"
        when "sagitta elegans"
          inp = "parasagitta elegans"
        when "alka torda"
          inp = "alka torda"
        when "Orcinus orca"
          inp = "orcinus orca"
        when "themisto libelulla"
          inp = "themisto libellula"
        when "gymnocanthus triscuspis"
          inp = "gymnocanthus tricuspis"
        else
          inp.downcase.strip!
        end
        return inp
      end
      return inp
    end

    #laboratory field
   def self.laboratory(inp)
     case inp
     when "University of Örebro"
        inp = "Örebro University"
     when "Ørebro,Sverige"
        inp = "Örebro University"
     when "Örebro (MeSO2-DDE: University of Ottawa)"
        inp = "Örebro University, University of Ottawa"
     when "Örebro (PCP + OH-HpCS: University of Ottowa)"
        inp = "Örebro University, University of Ottawa"
     when "Örebro"
        inp = "Örebro University"
     when "Institutt for energiekinetik Kjeller"
        inp = "IFE"
     when "Akvaplan-NIVA"
        inp = "Akvaplan-niva"
     when "Folkehelseinstitutt"
        inp = "Folkehelseinstituttet"
     else
        inp
     end
     return inp
   end

   #unit field
   def self.unit(inp)
     if inp == 'µg/g'
       return 'ng/g'
     end
     return inp
   end


  #tarsus
   def self.return_empty(inp)
     if inp == 'NA'
       return ''
     end
   end

   #unit field
   def self.people_responsible(inp)
     if inp == nil then return '' end
     if inp == 'Geir Wing Gabrielsen,' then return 'Geir Wing Gabrielsen,NPI' end
       return inp
   end

  #Excel has a tendency to add .0 to what it thinks is a number
   def self.remove_zero(inp)
      if inp.include? ".0" then inp.slice! ".0" end
        return inp.strip!
   end

   #sex field
   def self.sex(inp)
      case inp
      when "m"
        inp = "male"
      when "M"
        inp = "male"
      when "f"
        inp = "female"
      when "F"
        inp ="female"
      when "juv"
        inp ="juvenile"
      when "j"
        inp ="juvenile"
      when "J"
        inp ="juvenile"
      when "u"
        inp = "unknown"
      when "?"
        inp = "unknown"
      when "uncertain"
        inp = "unknown"
      else
        inp
      end
   end

   def self.removeEmpty(obj)
     #  if (@obj["date_report"] == "" || @obj["date_report"] == nil)
     #      @obj.tap { |k| k.delete("date_report") }
     #  end

     #Traverse @entry and remove all empty entries
     obj.each do | key, val |
       if  val == "" || val == nil || val == 0.0
         obj.delete(key)
       end
     end
     return obj
   end

   #Get hold of UUID for database storage
    def self.getUUID()
       return SecureRandom.uuid
    end

    #Get a timestamp - current time
    def self.timestamp()
       a = (Time.now).to_s
       b = a.split(" ")
       c = b[0].split("-")
       dt = DateTime.new(c[0].to_i, c[1].to_i, c[2].to_i, 12, 0, 0, 0)
       return dt.to_time.utc.iso8601
    end

    #If number exist, return it, if not return 0
    def self.check(numb)
       return (numb == nil ? 0 : numb.abs)
    end

    #Get date, convert to iso8601
    #Does not handle chars as month such as 6.june 2015 etc
    #Does not handle day in the middle, such as 04/23/2014 etc
    def self.iso8601time(inputdate2)
       inputdate = inputdate2.to_s

       if (inputdate == '' || inputdate == nil ) then return '' end


       #if only year
       if (inputdate.length == 6 && inputdate[4..6]==".0") || (inputdate.length == 4)
          dt = DateTime.new(inputdate[0..3].to_i, 1, 1, 12, 0, 0, 0)
          return dt.to_time.utc.iso8601
       end

       #Convert separator into .
       inputdate.gsub! '-', '.'
       inputarr = inputdate.split('.')
       if inputarr.length==2
         inputarr.push('01')
       end

        dt = DateTime.new(inputarr[0].to_i, inputarr[1].to_i, inputarr[2].to_i, 12, 0, 0, 0)
        return dt.to_time.utc.iso8601


       if (inputdate.include? (".*\\d.*"))
       a = (inputdate).to_s


       #Delimiter space, -, .,/
       b = inputdate.split(/\.|\s|\/|-/)
        if (b[1] == '0') then b[1] = '01' end
         b.push('01','01')

       #puts b[0] + "*" + b[1] + '*' + b[2]
       #Find out where the four digit is, aka year
       if b[0].size == 4 #Assume YYYY.MM.DD
            #  begin
             dt = DateTime.new(b[0].to_i, b[1].to_i, b[2].to_i, 12, 0, 0, 0)
          # rescue
          #   "Date failed -------------------------"
          #   dt = DateTime.new(1980, 1, 1, 12, 0, 0, 0)
          #end
       elsif b[2].size == 4  #Assume DD.MM.YYYY
             dt = DateTime.new(b[2].to_i, b[1].to_i, b[0].to_i, 12, 0, 0, 0)
       else
             puts "cannot read dateformat"
       end
             return dt.to_time.utc.iso8601
      end #if nil
       return ''
    end

    #Check if a read value exists
    def self.checkExistence(inp)
       if inp == '' || inp == nil
         return ''
       else
         return inp.to_s
       end
    end

    #Post to server
    def  self.postToServer(url,doc,auth,user,password)
     @uri = URI.parse(url)
     http = Net::HTTP.new(@uri.host, @uri.port);
     http.use_ssl = true;
     req = Net::HTTP::Post.new(@uri.path,{'Authorization' => auth, 'Content-Type' => 'application/json' })
     req.body = doc
     req.basic_auth(user, password)
     res2 = http.request(req)
     unless ((res2.header).inspect) == "#<Net::HTTPOK 200 OK readbody=true>"
         puts (res2.header).inspect
         puts (res2.body).inspect
         #FileUtils.mv 'leser/'+ filename, 'feilet/' + filename
     end
     return http #res2
   end

   header_arr = {
    'AD'=> ['HCB',"pesticides and industrial by products"],
    'AE'=> ['a_HCH',"pesticides and industrial by products"],
    'AF'=> ['b_HCH',"pesticides and industrial by products"],
    'AG'=> ['g_HCH',"pesticides and industrial by products"],
    'AF'=> ['heptachlor',"pesticides and industrial by products"],
    'AI'=> ['oxy_CHL',"pesticides and industrial by products"],
    'AJ'=> ['t_CHL',"pesticides and industrial by products"],
    'AK'=> ['c_CHL',"pesticides and industrial by products"],
   'AL'=> ['tn_CHL',"pesticides and industrial by products"],
   'AM'=> ['cn_CHL',"pesticides and industrial by products"],
   'AN'=> ['op_DDE',"pesticides and industrial by products"],
   'AO'=> ['pp_DDE',"pesticides and industrial by products"],
   'AP'=> ['op_DDD',"pesticides and industrial by products"],
   'AQ'=> ['pp_DDD',"pesticides and industrial by products"],
   'AR'=> ['op_DDT',"pesticides and industrial by products"],
   'AS'=> ['pp_DDT',"pesticides and industrial by products"],
   'AT'=> ['mirex',"pesticides and industrial by products"],
   'AU'=> ['aldrin',"pesticides and industrial by products"],
   'AV'=> ['dieldrin',"pesticides and industrial by products"],
   'AW'=> ['endrin',"pesticides and industrial by products"],
   'AX'=> ['heptachlor_epoxide',"pesticides and industrial by products"],
   'AY'=> ['CHB_26',"pesticides and industrial by products"],
   'AZ'=> ['CHB_40',"pesticides and industrial by products"],
   'BA'=> ['CHB_41',"pesticides and industrial by products"],
   'BB'=> ['CHB_44',"pesticides and industrial by products"],
   'BC'=> ['CHB_50',"pesticides and industrial by products"],
   'BD'=> ['CHB_62',"pesticides and industrial by products"],
   'BE'=> ['PCB_28',"polychlorinated biphenyls (PCBs)"],
    'BF'=> ['PCB_29',"polychlorinated biphenyls (PCBs)"],
    'BG'=> ['PCB_31',"polychlorinated biphenyls (PCBs)"],
    'BH'=> ['PCB_47',"polychlorinated biphenyls (PCBs)"],
    'BI'=> ['PCB_52',"polychlorinated biphenyls (PCBs)"],
    'BJ'=> ['PCB_56',"polychlorinated biphenyls (PCBs)"],
    'BK'=> ['PCB_66',"polychlorinated biphenyls (PCBs)"],
    'BL'=> ['PCB_74',"polychlorinated biphenyls (PCBs)"],
    'BM'=> ['PCB_87',"polychlorinated biphenyls (PCBs)"],
    'BN'=> ['PCB_99',"polychlorinated biphenyls (PCBs)"],
    'BO'=> ['PCB_101',"polychlorinated biphenyls (PCBs)"],
    'BP'=> ['PCB_105',"polychlorinated biphenyls (PCBs)"],
    'BQ'=> ['PCB_110',"polychlorinated biphenyls (PCBs)"],
    'BR'=> ['PCB_112',"polychlorinated biphenyls (PCBs)"],
    'BS'=> ['PCB_114',"polychlorinated biphenyls (PCBs)"],
    'BT'=> ['PCB_118',"polychlorinated biphenyls (PCBs)"],
    'BU'=> ['PCB_123',"polychlorinated biphenyls (PCBs)"],
    'BV'=> ['PCB_128',"polychlorinated biphenyls (PCBs)"],
    'BW'=> ['PCB_132',"polychlorinated biphenyls (PCBs)"],
    'BX'=> ['PCB_136',"polychlorinated biphenyls (PCBs)"],
    'BY'=> ['PCB_137',"polychlorinated biphenyls (PCBs)"],
    'BZ'=> ['PCB_138',"polychlorinated biphenyls (PCBs)"],
    'CA'=> ['PCB_141',"polychlorinated biphenyls (PCBs)"],
    'CB'=>  ['PCB_149',"polychlorinated biphenyls (PCBs)"],
    'CC'=> ['PCB_151',"polychlorinated biphenyls (PCBs)"],
   'CD'=> ['PCB_153',"polychlorinated biphenyls (PCBs)"],
   'CE'=> ['PCB_156',"polychlorinated biphenyls (PCBs)"],
   'CF'=> ['PCB_157',"polychlorinated biphenyls (PCBs)"],
   'CG'=> ['PCB_167',"polychlorinated biphenyls (PCBs)"],
   'CH'=> ['PCB_170',"polychlorinated biphenyls (PCBs)"],
   'CI'=> ['PCB_180',"polychlorinated biphenyls (PCBs)"],
   'CJ'=> ['PCB_183',"polychlorinated biphenyls (PCBs)"],
   'CK'=> ['PCB_187',"polychlorinated biphenyls (PCBs)"],
   'CL'=> ['PCB_189',"polychlorinated biphenyls (PCBs)"],
   'CM'=> ['PCB_194',"polychlorinated biphenyls (PCBs)"],
   'CN'=> ['PCB_196',"polychlorinated biphenyls (PCBs)"],
   'CO'=> ['PCB_199',"polychlorinated biphenyls (PCBs)"],
   'CP'=> ['PCB_206',"polychlorinated biphenyls (PCBs)"],
   'CQ'=> ['PCB_207',"polychlorinated biphenyls (PCBs)"],
   'CR'=> ['PCB_209',"polychlorinated biphenyls (PCBs)"],
   'CS'=> ['BDE_28',"brominated flame retardants (BFRs)"],
   'CT'=>  ['BDE_47',"brominated flame retardants (BFRs)"],
   'CU'=> ['BDE_77',"brominated flame retardants (BFRs)"],
   'CV'=> ['BDE_99',"brominated flame retardants (BFRs)"],
   'CW'=> ['BDE_100',"brominated flame retardants (BFRs)"],
   'CX'=> ['BDE_153',"brominated flame retardants (BFRs)"],
   'CY'=> ['BDE_154',"brominated flame retardants (BFRs)"],
   'CZ'=> ['BDE_183',"brominated flame retardants (BFRs)"],
   'DA'=> ['BDE_206',"brominated flame retardants (BFRs)"],
    'DB'=> ['BDE_207',"brominated flame retardants (BFRs)"],
    'DC'=> ['BDE_208',"brominated flame retardants (BFRs)"],
    'DD'=> ['BDE_209',"brominated flame retardants (BFRs)"],
    'DE'=> ['HBCDD',"brominated flame retardants (BFRs)"],
    'DF'=> ['PBT',"brominated flame retardants (BFRs)"],
    'DG'=> ['PBEB',"brominated flame retardants (BFRs)"],
    'DH'=> ['DPTE',"brominated flame retardants (BFRs)"],
    'DI'=> ['HBB',"brominated flame retardants (BFRs)"],
    'DJ'=> ['PCP',"polychlorinated biphenyls (PCBs)"],
    'DK'=> ['Z4_OH_CB106',"metabolized polychlorinated biphenyls (PCBs)"],
    'DL'=> ['Z4_OH_CB107',"metabolized polychlorinated biphenyls (PCBs)"],
    'DM'=> ['Z4_OH_CB108',"metabolized polychlorinated biphenyls (PCBs)"],
    'DN'=> ['Z3_OH_CB118',"metabolized polychlorinated biphenyls (PCBs)"],
    'DO'=> ['Z4_OH_BDE42',"metabolized brominated flame retardants (BFRs)"],
    'DP'=> ['Z3_OH_BDE47',"metabolized brominated flame retardants (BFRs)"],
    'DQ'=> ['Z6_OH_BDE47',"metabolized brominated flame retardants (BFRs)"],
    'DR'=> ['Z4_OH_BDE49',"metabolized brominated flame retardants (BFRs)"],
    'DS'=> ['Z2_OH_BDE68',"metabolized brominated flame retardants (BFRs)"],
    'DT'=> ['Z4_OH_CB130',"metabolized polychlorinated biphenyls (PCBs)"],
    'DU'=> ['Z3_OH_CB138',"metabolized polychlorinated biphenyls (PCBs)"],
    'DV'=> ['Z4_OH_CB146',"metabolized polychlorinated biphenyls (PCBs)"],
    'DW'=> ['Z4_OH_CB159',"metabolized polychlorinated biphenyls (PCBs)"],
    'DX'=> ['Z4_OH_CB172',"metabolized polychlorinated biphenyls (PCBs)"],
    'DY'=> ['Z3_OH_CB180',"metabolized polychlorinated biphenyls (PCBs)"],
    'DZ'=> ['Z4_OH_CB187',"metabolized polychlorinated biphenyls (PCBs)"],
    'EA'=> ['PFHxA',"poly- and perfluoroalkyl subtances (PFAS)"],
    'EB'=> ['PFHpA',"poly- and perfluoroalkyl subtances (PFAS)"],
    'EC'=> ['PFOA',"poly- and perfluoroalkyl subtances (PFAS)"],
    'ED'=> ['PFNA',"poly- and perfluoroalkyl subtances (PFAS)"],
    'EE'=> ['PFDA',"poly- and perfluoroalkyl subtances (PFAS)"],
    'EF'=> ['PFUnDA',"poly- and perfluoroalkyl subtances (PFAS)"],
    'EG'=> ['PFDoDA',"poly- and perfluoroalkyl subtances (PFAS)"],
    'EH'=> ['PFTrDA',"poly- and perfluoroalkyl subtances (PFAS)"],
    'EI'=> ['PFTeDA',"poly- and perfluoroalkyl subtances (PFAS)"],
    'EJ'=> ['PFBS',"poly- and perfluoroalkyl subtances (PFAS)"],
    'EK'=> ['PFHxS',"poly- and perfluoroalkyl subtances (PFAS)"],
    'EL'=> ['PFOS',"poly- and perfluoroalkyl subtances (PFAS)"],
    'EM'=> ['FOSA',"poly- and perfluoroalkyl subtances (PFAS)"],
    'EN'=> ['N_MeFOSA',"poly- and perfluoroalkyl subtances (PFAS)"],
    'EO'=>['N_MeFOSE',"poly- and perfluoroalkyl subtances (PFAS)"],
    'EP'=> ['N_EtFOSA',"poly- and perfluoroalkyl subtances (PFAS)"],
    'EQ'=> ['N_EtFOSE',"poly- and perfluoroalkyl subtances (PFAS)"],
    'ES'=> ['brPFOS',"poly- and perfluoroalkyl subtances (PFAS)"],
    'ET'=> ['linPFOS',"poly- and perfluoroalkyl subtances (PFAS)"],
    'EU'=> ['PFOSbr2',"poly- and perfluoroalkyl subtances (PFAS)"],
    'EV'=> ['PFOSlin2',"poly- and perfluoroalkyl subtances (PFAS)"],
    'EW'=> ['FTSA',"poly- and perfluoroalkyl subtances (PFAS)"],
    'EX'=> ['PFHpS',"poly- and perfluoroalkyl subtances (PFAS)"],
    'EY'=> ['PFPeA',"poly- and perfluoroalkyl subtances (PFAS)"],
    'EZ'=> ['PFPeDA',"poly- and perfluoroalkyl subtances (PFAS)"],
    'FA'=> ['PECB',"poly- and perfluoroalkyl subtances (PFAS)"],
    'FB'=> ['PFNS',"poly- and perfluoroalkyl subtances (PFAS)"],
    'FC'=> ['PFDS',"poly- and perfluoroalkyl subtances (PFAS)"],
    'FD'=> ['PFBA',"poly- and perfluoroalkyl subtances (PFAS)"],
    'FE'=> ['Z1_3_DCB',"pesticides and industrial by products"],
    'FF'=> ['Z1_4_DCB',"pesticides and industrial by products"],
    'FG'=> ['Z1_2_DCB',"pesticides and industrial by products"],
    'FH'=> ['Z1_3_5_TCB',"pesticides and industrial by products"],
    'FI'=> ['Z1_2_4_TCB',"pesticides and industrial by products"],
    'FJ'=> ['Z1_2_3_TCB',"pesticides and industrial by products"],
    'FK'=> ['hexachlorobutadiene',"pesticides and industrial by products"],
    'FL'=> ['Z1_2_3_4_TTCB',"pesticides and industrial by products"],
    'FM'=> ['pentachloroanisole',"pesticides and industrial by products"],
    'FN'=> ['octachlorostyrene',"pesticides and industrial by products"],
    'FO'=> ['a_endosulfan',"pesticides and industrial by products"],
    'FP'=> ['b_endosulfan',"pesticides and industrial by products"],
    'FQ'=> ['methoxychlor',"pesticides and industrial by products"],
    'FR'=> ['Z4_2_FTS',"fluorotelomer carboxylic acids (FTCAs)"],
    'FS'=> ['Z6_2_FTS',"fluorotelomer carboxylic acids (FTCAs)"],
    'FT'=> ['Z8_2_FTS',"fluorotelomer carboxylic acids (FTCAs)"],
    'FU'=> ['Z8_2_FTCA',"fluorotelomer carboxylic acids (FTCAs)"],
    'FV'=> ['Z8_2_FTUCA',"fluorotelomer carboxylic acids (FTCAs)"],
   'FW'=> ['Z10_2_FTCA',"fluorotelomer carboxylic acids (FTCAs)"],
   'FX'=> ['Z10_2_FTUCA',"fluorotelomer carboxylic acids (FTCAs)"],
   'FY'=> ['CHB_32',"pesticides and industrial by products"],
   'FZ'=> ['CHB_38',"pesticides and industrial by products"],
   'GA'=> ['CHB_58',"pesticides and industrial by products"],
   'GB'=> ['CHB_69',"pesticides and industrial by products"],
   'GC'=> ['BCP', "radioactive compounds"],
   'GD'=> ['Z3_MeSO2_DDE', "metabolized pesticides and industrial by products"],
   'GE'=> ['CDT',"radioactive compounds"],
   'GF'=> ['DDE_PCB_87',"pesticides and industrial by products"],
   'GG'=> ['OCS',"pesticides and industrial by products"],
   'GH'=> ['photomirex',"pesticides and industrial by products"],
   'GI'=> ['HCBD',"pesticides and industrial by products"],
   'GJ'=> ['ChCl',"pesticides and industrial by products"],
   'GK'=> ['MC6',"pesticides and industrial by products"],
   'GL'=> ['B6_923a',"pesticides and industrial by products"],
   'GM'=> ['B7_499',"pesticides and industrial by products"],
   'GN'=> ['B7_515',"pesticides and industrial by products"],
   'GO'=> ['B7_1474_B7_1440',"pesticides and industrial by products"],
   'GP'=> ['B7_1001',"pesticides and industrial by products"],
   'GQ'=> ['B7_1059a',"pesticides and industrial by products"],
    'GR'=> ['B7_1450',"pesticides and industrial by products"],
    'GS'=> ['B8_531',"pesticides and industrial by products"],
    'GT'=> ['B8_789',"pesticides and industrial by products"],
    'GU'=> ['B8_806',"pesticides and industrial by products"],
    'GV'=> ['B8_810',"pesticides and industrial by products"],
    'GW'=> ['B8_1412',"pesticides and industrial by products"],
    'GX'=> ['B8_1413',"pesticides and industrial by products"],
    'GY'=> ['B8_1414',"pesticides and industrial by products"],
    'GZ'=> ['B8_1471',"pesticides and industrial by products"],
    'HA'=> ['B8_2229',"pesticides and industrial by products"],
    'HB'=> ['B9_715',"pesticides and industrial by products"],
    'HC'=> ['B9_718',"pesticides and industrial by products"],
    'HD'=> ['B9_743_B9_2006',"pesticides and industrial by products"],
    'HE'=> ['B9_1025',"pesticides and industrial by products"],
    'HF'=> ['B9_1046',"pesticides and industrial by products"],
    'HG'=> ['B9_1679',"pesticides and industrial by products"],
    'HH'=> ['B10_1110',"pesticides and industrial by products"],
    'HI'=> ['PCB_1',"polychlorinated biphenyls (PCBs)"],
    'HJ'=> ['PCB_3',"polychlorinated biphenyls (PCBs)"],
    'HK'=> ['PCB_4_10',"polychlorinated biphenyls (PCBs)"],
    'HL'=> ['PCB_6',"polychlorinated biphenyls (PCBs)"],
    'HM'=> ['PCB_7_9',"polychlorinated biphenyls (PCBs)"],
    'HN'=> ['PCB_8_5',"polychlorinated biphenyls (PCBs)"],
    'HO'=> ['PCB_12_13',"polychlorinated biphenyls (PCBs)"],
    'HP'=> ['PCB_15_17',"polychlorinated biphenyls (PCBs)"],
    'HQ'=> ['PCB_16_32',"polychlorinated biphenyls (PCBs)"],
    'HR'=> ['PCB_18',"polychlorinated biphenyls (PCBs)"],
    'HS'=> ['PCB_19',"polychlorinated biphenyls (PCBs)"],
    'HT'=> ['PCB_20',"polychlorinated biphenyls (PCBs)"],
    'HU'=> ['PCB_22',"polychlorinated biphenyls (PCBs)"],
    'HV'=> ['PCB_24_27',"polychlorinated biphenyls (PCBs)"],
    'HW'=> ['PCB_25',"polychlorinated biphenyls (PCBs)"],
    'HX'=> ['PCB_26',"polychlorinated biphenyls (PCBs)"],
    'HY'=> ['PCB_28_31',"polychlorinated biphenyls (PCBs)"],
    'HZ'=> ['PCB_31_28',"polychlorinated biphenyls (PCBs)"],
    'IA'=> ['PCB_33',"polychlorinated biphenyls (PCBs)"],
    'IB'=> ['PCB_33_20',"polychlorinated biphenyls (PCBs)"],
    'IC'=> ['PCB_37',"polychlorinated biphenyls (PCBs)"],
    'ID'=> ['PCB_38',"polychlorinated biphenyls (PCBs)"],
    'IE'=> ['PCB_40',"polychlorinated biphenyls (PCBs)"],
    'IF'=> ['PCB_42',"polychlorinated biphenyls (PCBs)"],
    'IG'=> ['PCB_43',"polychlorinated biphenyls (PCBs)"],
    'IH'=> ['PCB_44',"polychlorinated biphenyls (PCBs)"],
    'II'=> ['PCB_45',"polychlorinated biphenyls (PCBs)"],
    'IJ'=> ['PCB_46',"polychlorinated biphenyls (PCBs)"],
    'IK'=> ['PCB_48',"polychlorinated biphenyls (PCBs)"],
    'IL'=> ['PCB_49',"polychlorinated biphenyls (PCBs)"],
    'IM'=> ['PCB_47_48',"polychlorinated biphenyls (PCBs)"],
    'IN'=> ['PCB_47_49',"polychlorinated biphenyls (PCBs)"],
    'IO'=> ['PCB_50',"polychlorinated biphenyls (PCBs)"],
    'IP'=> ['PCB_51',"polychlorinated biphenyls (PCBs)"],
    'IQ'=> ['PCB_53',"polychlorinated biphenyls (PCBs)"],
    'IR'=> ['PCB_54_29',"polychlorinated biphenyls (PCBs)"],
    'IS'=> ['PCB_55',"polychlorinated biphenyls (PCBs)"],
    'IT'=> ['PCB_56_60',"polychlorinated biphenyls (PCBs)"],
    'IU'=> ['PCB_59',"polychlorinated biphenyls (PCBs)"],
    'IV'=> ['PCB_60',"polychlorinated biphenyls (PCBs)"],
    'IW'=> ['PCB_63',"polychlorinated biphenyls (PCBs)"],
    'IX'=> ['PCB_64',"polychlorinated biphenyls (PCBs)"],
    'IY'=> ['PCB_64_41',"polychlorinated biphenyls (PCBs)"],
    'IZ'=> ['PCB_66_95',"polychlorinated biphenyls (PCBs)"],
    'JA'=> ['PCB_70',"polychlorinated biphenyls (PCBs)"],
    'JB'=> ['PCB_70_74',"polychlorinated biphenyls (PCBs)"],
    'JC'=> ['PCB_70_76',"polychlorinated biphenyls (PCBs)"],
    'JD'=> ['PCB_70_76_98',"polychlorinated biphenyls (PCBs)"],
    'JE'=> ['PCB_71_41_64',"polychlorinated biphenyls (PCBs)"],
    'JF'=> ['PCB_76',"polychlorinated biphenyls (PCBs)"],
    'JG'=> ['PCB_77',"polychlorinated biphenyls (PCBs)"],
    'JH'=> ['PCB_81',"polychlorinated biphenyls (PCBs)"],
    'JI'=> ['PCB_81_87',"polychlorinated biphenyls (PCBs)"],
    'JJ'=> ['PCB_82',"polychlorinated biphenyls (PCBs)"],
    'JK'=> ['PCB_83',"polychlorinated biphenyls (PCBs)"],
    'JL'=> ['PCB_84',"polychlorinated biphenyls (PCBs)"],
    'JM'=> ['PCB_85',"polychlorinated biphenyls (PCBs)"],
    'JN'=> ['PCB_91',"polychlorinated biphenyls (PCBs)"],
    'JO'=> ['PCB_92',"polychlorinated biphenyls (PCBs)"],
    'JP'=> ['PCB_95',"polychlorinated biphenyls (PCBs)"],
    'JQ'=> ['PCB_97',"polychlorinated biphenyls (PCBs)"],
    'JR'=> ['PCB_99_113',"polychlorinated biphenyls (PCBs)"],
    'JS'=> ['PCB_100',"polychlorinated biphenyls (PCBs)"],
    'JT'=> ['PCB_101_90',"polychlorinated biphenyls (PCBs)"],
    'JU'=> ['PCB_107',"polychlorinated biphenyls (PCBs)"],
    'JV'=> ['PCB_113',"polychlorinated biphenyls (PCBs)"],
    'JW'=> ['PCB_114_122',"polychlorinated biphenyls (PCBs)"],
    'JX'=> ['PCB_119',"polychlorinated biphenyls (PCBs)"],
    'JY'=> ['PCB_122',"polychlorinated biphenyls (PCBs)"],
    'JZ'=> ['PCB_126',"polychlorinated biphenyls (PCBs)"],
    'KA'=> ['PCB_129',"polychlorinated biphenyls (PCBs)"],
    'KB'=>['PCB_129_178',"polychlorinated biphenyls (PCBs)"],
    'KC'=> ['PCB_130',"polychlorinated biphenyls (PCBs)"],
    'KD'=> ['PCB_133',"polychlorinated biphenyls (PCBs)"],
    'KE'=> ['PCB_134_131',"polychlorinated biphenyls (PCBs)"],
    'KF'=> ['PCB_135_144',"polychlorinated biphenyls (PCBs)"],
    'KG'=> ['PCB_138_164',"polychlorinated biphenyls (PCBs)"],
    'KH'=> ['PCB_146',"polychlorinated biphenyls (PCBs)"],
    'KI'=> ['PCB_147',"polychlorinated biphenyls (PCBs)"],
    'KJ'=> ['PCB_157_201',"polychlorinated biphenyls (PCBs)"],
    'KK'=> ['PCB_158',"polychlorinated biphenyls (PCBs)"],
    'KL'=> ['PCB_163_138',"polychlorinated biphenyls (PCBs)"],
    'KM'=> ['PCB_169',"polychlorinated biphenyls (PCBs)"],
    'KN'=> ['PCB_170_190',"polychlorinated biphenyls (PCBs)"],
    'KO'=> ['PCB_171',"polychlorinated biphenyls (PCBs)"],
    'KP'=> ['PCB_171_202',"polychlorinated biphenyls (PCBs)"],
    'KQ'=> ['PCB_171_202_156',"polychlorinated biphenyls (PCBs)"],
    'KR'=> ['PCB_172',"polychlorinated biphenyls (PCBs)"],
    'KS'=> ['PCB_172_192',"polychlorinated biphenyls (PCBs)"],
    'KT'=> ['PCB_173',"polychlorinated biphenyls (PCBs)"],
    'KU'=> ['PCB_174',"polychlorinated biphenyls (PCBs)"],
    'KV'=> ['PCB_175',"polychlorinated biphenyls (PCBs)"],
    'KW'=> ['PCB_176',"polychlorinated biphenyls (PCBs)"],
    'KX'=> ['PCB_177',"polychlorinated biphenyls (PCBs)"],
    'KY'=> ['PCB_178',"polychlorinated biphenyls (PCBs)"],
    'KZ'=> ['PCB_179',"polychlorinated biphenyls (PCBs)"],
    'LA'=> ['PCB_180_193',"polychlorinated biphenyls (PCBs)"],
    'LB'=> ['PCB_182_187',"polychlorinated biphenyls (PCBs)"],
    'LC'=> ['PCB_185',"polychlorinated biphenyls (PCBs)"],
    'LD'=> ['PCB_191',"polychlorinated biphenyls (PCBs)"],
    'LE'=> ['PCB_193',"polychlorinated biphenyls (PCBs)"],
    'LF'=> ['PCB_195',"polychlorinated biphenyls (PCBs)"],
    'LG'=> ['PCB_196_203',"polychlorinated biphenyls (PCBs)"],
    'LH'=> ['PCB_197',"polychlorinated biphenyls (PCBs)"],
    'LI'=> ['PCB_198',"polychlorinated biphenyls (PCBs)"],
    'LJ'=> ['PCB_200',"polychlorinated biphenyls (PCBs)"],
    'LK'=> ['PCB_201',"polychlorinated biphenyls (PCBs)"],
    'LL'=> ['PCB_201_204',"polychlorinated biphenyls (PCBs)"],
    'LM'=> ['PCB_202',"polychlorinated biphenyls (PCBs)"],
    'LN'=> ['PCB_202_171',"polychlorinated biphenyls (PCBs)"],
    'LO'=> ['PCB_203',"polychlorinated biphenyls (PCBs)"],
    'LP'=> ['PCB_203_196',"polychlorinated biphenyls (PCBs)"],
    'LQ'=> ['PCB_204',"polychlorinated biphenyls (PCBs)"],
    'LR'=> ['PCB_205',"polychlorinated biphenyls (PCBs)"],
    'LS'=> ['PCB_208',"polychlorinated biphenyls (PCBs)"],
    'LT'=> ['PCB_208_195',"polychlorinated biphenyls (PCBs)"],
    'LU'=> ['PCB_138_163',"polychlorinated biphenyls (PCBs)"],
    'LV'=> ['PCB_153_132',"polychlorinated biphenyls (PCBs)"],
    'LW'=> ['Z4_OH_CB79',"metabolized polychlorinated biphenyls (PCBs)"],
    'LX'=> ['Z3_OH_CB85',"metabolized polychlorinated biphenyls (PCBs)"],
    'LY'=> ['Z4_OH_CB97',"metabolized polychlorinated biphenyls (PCBs)"],
    'LZ'=> ['Z4_OH_CB104',"metabolized polychlorinated biphenyls (PCBs)"],
    'MA'=> ['Z4_OH_CB107_4_OH_CB108',"metabolized polychlorinated biphenyls (PCBs)"],
    'MB'=> ['Z4_OH_CB112',"metabolized polychlorinated biphenyls (PCBs)"],
    'MC'=> ['Z2_OH_CB114',"metabolized polychlorinated biphenyls (PCBs)"],
    'MD'=> ['Z4_OH_CB120',"metabolized polychlorinated biphenyls (PCBs)"],
    'ME'=> ['Z4_OH_CB127',"metabolized polychlorinated biphenyls (PCBs)"],
    'MF'=> ['Z4_OH_CB134',"metabolized polychlorinated biphenyls (PCBs)"],
    'MG'=> ['Z3_OH_CB153',"metabolized polychlorinated biphenyls (PCBs)"],
    'MH'=> ['Z4_OH_CB162',"metabolized polychlorinated biphenyls (PCBs)"],
    'MI'=> ['Z4_OH_CB163',"metabolized polychlorinated biphenyls (PCBs)"],
    'MJ'=> ['Z4_OH_CB165',"metabolized polychlorinated biphenyls (PCBs)"],
    'MK'=> ['Z4_OH_CB177',"metabolized polychlorinated biphenyls (PCBs)"],
    'ML'=> ['Z4_OH_CB178',"metabolized polychlorinated biphenyls (PCBs)"],
    'MM'=> ['Z3_OH_CB182',"metabolized polychlorinated biphenyls (PCBs)"],
    'MN'=> ['Z3_OH_CB183',"metabolized polychlorinated biphenyls (PCBs)"],
    'MO'=> ['Z3_OH_CB184',"metabolized polychlorinated biphenyls (PCBs)"],
    'MP'=> ['Z4_OH_CB193',"metabolized polychlorinated biphenyls (PCBs)"],
    'MQ'=> ['Z4_OH_CB198',"metabolized polychlorinated biphenyls (PCBs)"],
    'MR'=> ['Z4_OH_CB199',"metabolized polychlorinated biphenyls (PCBs)"],
    'MS'=> ['Z4_OH_CB200',"metabolized polychlorinated biphenyls (PCBs)"],
    'MT'=> ['Z4_OH_CB201',"metabolized polychlorinated biphenyls (PCBs)"],
    'MU'=> ['Z4_OH_CB202',"metabolized polychlorinated biphenyls (PCBs)"],
    'MV'=> ['Z44_diOH_CB202',"metabolized polychlorinated biphenyls (PCBs)"],
    'MW'=> ['Z3_OH_CB203',"metabolized polychlorinated biphenyls (PCBs)"],
    'MX'=> ['Z4_OH_CB208',"metabolized polychlorinated biphenyls (PCBs)"],
    'MY'=> ['Z10_OH_CB', "radioactive compounds"],
    'MZ'=> ['Z3_MeSO2_CB49',"metabolized polychlorinated biphenyls (PCBs)"],
    'NA'=> ['Z4_MeSO2_CB49',"metabolized polychlorinated biphenyls (PCBs)"],
    'NB'=> ['Z3_MeSO2_CB52',"metabolized polychlorinated biphenyls (PCBs)"],
    'NC'=> ['Z4_MeSO2_CB52',"metabolized polychlorinated biphenyls (PCBs)"],
    'ND'=> ['Z4_MeSO2_CB64',"metabolized polychlorinated biphenyls (PCBs)"],
    'NE'=> ['Z3_MeSO2_CB70',"metabolized polychlorinated biphenyls (PCBs)"],
    'NF'=> ['Z4_MeSO2_CB70',"metabolized polychlorinated biphenyls (PCBs)"],
    'NG'=> ['Z3_MeSO2_CB87',"metabolized polychlorinated biphenyls (PCBs)"],
    'NH'=> ['Z4_MeSO2_CB87',"metabolized polychlorinated biphenyls (PCBs)"],
    'NI'=> ['Z3_MeSO2_CB91',"metabolized polychlorinated biphenyls (PCBs)"],
    'NJ'=> ['Z4_MeSO2_CB91',"metabolized polychlorinated biphenyls (PCBs)"],
    'NK'=> ['Z3_MeSO2_CB101',"metabolized polychlorinated biphenyls (PCBs)"],
    'NL'=> ['Z4_MeSO2_CB101',"metabolized polychlorinated biphenyls (PCBs)"],
    'NM'=> ['Z3_MeSO2_CB110',"metabolized polychlorinated biphenyls (PCBs)"],
    'NN'=> ['Z4_MeSO2_CB110',"metabolized polychlorinated biphenyls (PCBs)"],
    'NO'=> ['Z3_MeSO2_CB149',"metabolized polychlorinated biphenyls (PCBs)"],
    'NP'=> ['Z4_MeSO2_CB149',"metabolized polychlorinated biphenyls (PCBs)"],
    'NQ'=> ['Z3_MeSO2_CB132',"metabolized polychlorinated biphenyls (PCBs)"],
    'NR'=> ['Z4_MeSO2_CB132',"metabolized polychlorinated biphenyls (PCBs)"],
    'NS'=> ['Z3_MeSO2_CB141',"metabolized polychlorinated biphenyls (PCBs)"],
    'NT'=> ['Z4_MeSO2_CB141',"metabolized polychlorinated biphenyls (PCBs)"],
    'NU'=> ['Z3_MeSO2_CB174',"metabolized polychlorinated biphenyls (PCBs)"],
    'NV'=> ['Z4_MeSO2_CB174',"metabolized polychlorinated biphenyls (PCBs)"],
    'NW'=> ['Z19_MeSO2_CB',"metabolized polychlorinated biphenyls (PCBs)"],
    'NX'=> ['BDE_17',"brominated flame retardants (BFRs)"],
    'NY'=> ['BDE_25',"brominated flame retardants (BFRs)"],
    'NZ'=> ['BDE_49',"brominated flame retardants (BFRs)"],
    'OA'=> ['BDE_54',"brominated flame retardants (BFRs)"],
    'OB'=> ['BDE_66',"brominated flame retardants (BFRs)"],
    'OC'=> ['BDE_71',"brominated flame retardants (BFRs)"],
    'OD'=> ['BDE_71_49',"brominated flame retardants (BFRs)"],
    'OE'=> ['BDE_75',"brominated flame retardants (BFRs)"],
    'OF'=> ['BDE_85',"brominated flame retardants (BFRs)"],
    'OG'=> ['BDE_116',"brominated flame retardants (BFRs)"],
    'OH'=> ['BDE_119',"brominated flame retardants (BFRs)"],
    'OI'=> ['BDE_126',"brominated flame retardants (BFRs)"],
    'OJ'=> ['BDE_138',"brominated flame retardants (BFRs)"],
    'OK'=> ['BDE_139',"brominated flame retardants (BFRs)"],
    'OL'=> ['BDE_140',"brominated flame retardants (BFRs)"],
    'OM'=> ['BDE_155',"brominated flame retardants (BFRs)"],
    'ON'=> ['BDE_100_5_MeO_BDE47',"brominated flame retardants (BFRs)"],
    'OO'=> ['BDE_154_BB153',"brominated flame retardants (BFRs)"],
    'OP'=> ['BDE_156',"brominated flame retardants (BFRs)"],
    'OQ'=> ['BDE_171',"brominated flame retardants (BFRs)"],
    'OR'=> ['BDE_180',"brominated flame retardants (BFRs)"],
    'OS'=> ['BDE_181',"brominated flame retardants (BFRs)"],
    'OT'=> ['BDE_184',"brominated flame retardants (BFRs)"],
    'OU'=> ['BDE_190',"brominated flame retardants (BFRs)"],
    'OV'=> ['BDE_191',"brominated flame retardants (BFRs)"],
    'OW'=> ['BDE_196',"brominated flame retardants (BFRs)"],
    'OX'=> ['BDE_197',"brominated flame retardants (BFRs)"],
    'OY'=> ['BDE_201',"brominated flame retardants (BFRs)"],
    'OZ'=> ['BDE_202',"brominated flame retardants (BFRs)"],
    'PA'=> ['BDE_203',"brominated flame retardants (BFRs)"],
    'PB'=> ['BDE_205',"brominated flame retardants (BFRs)"],
    'PC'=> ['BDE_208_207',"brominated flame retardants (BFRs)"],
    'PD'=> ['a_HBCD',"brominated flame retardants (BFRs)"],
    'PE'=> ['b_HBCD',"brominated flame retardants (BFRs)"],
    'PF'=> ['g_HBCD',"brominated flame retardants (BFRs)"],
    'PG'=> ['TBPA',"brominated flame retardants (BFRs)"],
    'PH'=> ['BTBPE',"brominated flame retardants (BFRs)"],
    'PI'=> ['TBB',"brominated flame retardants (BFRs)"],
    'PJ'=>  ['TBBPA_DBPE',"brominated flame retardants (BFRs)"],
    'PK'=> ['DPDPE',"brominated flame retardants (BFRs)"],
    'PL'=> ['ATE',"brominated flame retardants (BFRs)"],
    'PM'=> ['BEHTBP',"brominated flame retardants (BFRs)"],
    'PN'=> ['TBP',"brominated flame retardants (BFRs)"],
    'PO'=> ['BTBPI',"brominated flame retardants (BFRs)"],
    'PP'=> ['TBBPA_DAE',"brominated flame retardants (BFRs)"],
    'PQ'=> ['EHTBB',"brominated flame retardants (BFRs)"],
    'PR'=> ['DBDPE',"brominated flame retardants (BFRs)"],
    'PS'=> ['TBA',"brominated flame retardants (BFRs)"],
    'PT'=> ['TBBPA',"brominated flame retardants (BFRs)"],
    'PU'=> ['Z4_OH_HpCS',"pesticides and industrial by products"],
    'PV'=> ['Z44_DiBB',"brominated flame retardants (BFRs)"],
    'PW'=> ['Z2255_TetBB',"brominated flame retardants (BFRs)"],
    'PX'=> ['Z224455_HexBB',"brominated flame retardants (BFRs)"],
    'PY'=> ['Z6_MeO_BDE17',"metabolized brominated flame retardants (BFRs)"],
    'PZ'=> ['Z4_MeO_BDE17',"metabolized brominated flame retardants (BFRs)"],
    'QA'=> ['Z2_MeO_BDE28',"metabolized brominated flame retardants (BFRs)"],
    'QB'=> ['Z4_MeO_BDE42',"metabolized brominated flame retardants (BFRs)"],
    'QC'=> ['Z6_MeO_BDE47',"metabolized brominated flame retardants (BFRs)"],
    'QD'=> ['Z3_MeO_BDE47',"metabolized brominated flame retardants (BFRs)"],
    'QE'=> ['Z5_MeO_BDE47',"metabolized brominated flame retardants (BFRs)"],
    'QF'=> ['Z5_MeO_BDE47_4_MeO_BDE49',"metabolized brominated flame retardants (BFRs)"],
    'QG'=> ['Z4_MeO_BDE49',"metabolized brominated flame retardants (BFRs)"],
    'QH'=> ['Z6_MeO_BDE49',"metabolized brominated flame retardants (BFRs)"],
    'QI'=> ['Z2_MeO_BDE68',"metabolized brominated flame retardants (BFRs)"],
    'QJ'=> ['Z6_MeO_BDE85',"metabolized brominated flame retardants (BFRs)"],
    'QK'=> ['Z6_MeO_BDE90',"metabolized brominated flame retardants (BFRs)"],
    'QL'=> ['Z6_MeO_BDE99',"metabolized brominated flame retardants (BFRs)"],
    'QM'=> ['Z2_MeO_BDE123',"metabolized brominated flame retardants (BFRs)"],
    'QN'=> ['Z6_MeO_BDE137',"metabolized brominated flame retardants (BFRs)"],
    'QO'=> ['Z8_OH_BDE',"metabolized brominated flame retardants (BFRs)"],
    'QP'=> ['Z6_OH_BDE17',"metabolized brominated flame retardants (BFRs)"],
    'QQ'=> ['Z4_OH_BDE17',"metabolized brominated flame retardants (BFRs)"],
    'QR'=> ['Z5_OH_BDE47',"metabolized brominated flame retardants (BFRs)"],
    'QS'=> ['Z6_OH_BDE47_75',"metabolized brominated flame retardants (BFRs)"],
    'QT'=> ['Z6_OH_BDE49',"metabolized brominated flame retardants (BFRs)"],
    'QU'=> ['Z6_OH_BDE85',"metabolized brominated flame retardants (BFRs)"],
    'QV'=> ['Z6_OH_BDE90',"metabolized brominated flame retardants (BFRs)"],
    'QW'=> ['Z5_OH_BDE99',"metabolized brominated flame retardants (BFRs)"],
    'QX'=> ['Z5_OH_BDE100',"metabolized brominated flame retardants (BFRs)"],
    'QY'=> ['Z4_OH_BDE101',"metabolized brominated flame retardants (BFRs)"],
    'QZ'=> ['Z4_OH_BDE103',"metabolized brominated flame retardants (BFRs)"],
    'RA'=> ['Z2_OH_BDE123',"metabolized brominated flame retardants (BFRs)"],
    'RB'=> ['Z6_OH_BDE137',"metabolized brominated flame retardants (BFRs)"],
    'RC'=> ['naphthalene',"pesticides and industrial by products"],
    'RD'=> ['Z2_metylnaphtalene',"pesticides and industrial by products"],
    'RE'=> ['Z1_metylnaphtalene',"pesticides and industrial by products"],
    'RF'=> ['biphenyl',"pesticides and industrial by products"],
    'RG'=> ['acenaphthylene',"pesticides and industrial by products"],
    'RH'=> ['acenaphthene',"pesticides and industrial by products"],
    'RI'=> ['dibenzofuran',"pesticides and industrial by products"],
    'RJ'=> ['fluorene',"pesticides and industrial by products"],
    'RK'=> ['dibenzotiophene',"pesticides and industrial by products"],
    'RL'=> ['phenanthrene',"pesticides and industrial by products"],
    'RM'=> ['antracene',"pesticides and industrial by products"],
    'RN'=> ['Z3_metylphenantrene',"pesticides and industrial by products"],
    'RO'=> ['Z2_metylphenantrene',"pesticides and industrial by products"],
    'RP'=> ['Z2_metylantracene',"pesticides and industrial by products"],
    'RQ'=> ['Z9_metylphenantrene',"pesticides and industrial by products"],
    'RR'=> ['Z1_metylphenantrene',"pesticides and industrial by products"],
    'RS'=> ['fluoranthene',"pesticides and industrial by products"],
    'RT'=> ['pyrene',"pesticides and industrial by products"],
    'RU'=> ['benzo_a_fluorene',"pesticides and industrial by products"],
    'RV'=> ['retene',"pesticides and industrial by products"],
    'RW'=> ['benzo_b_fluorene',"pesticides and industrial by products"],
    'RX'=> ['benzo_ghi_fluoranthene',"pesticides and industrial by products"],
    'RY'=> ['cyclopenta_cd_pyrene',"pesticides and industrial by products"],
    'RZ'=> ['benzo_a_anthracene',"pesticides and industrial by products"],
    'SA'=> ['chrysene',"pesticides and industrial by products"],
    'SB'=> ['benzo_bjk_fluoranthene',"pesticides and industrial by products"],
    'SC'=> ['benzo_b_fluoranthene',"pesticides and industrial by products"],
    'SD'=> ['benzo_k_fluoranthene',"pesticides and industrial by products"],
    'SE'=> ['benzo_a_fluoranthene',"pesticides and industrial by products"],
    'SF'=> ['benzo_e_pyrene',"pesticides and industrial by products"],
    'SG'=> ['benzo_a_pyrene',"pesticides and industrial by products"],
    'SH'=> ['perylene',"pesticides and industrial by products"],
    'SI'=> ['indeno_123_cd_pyrene',"pesticides and industrial by products"],
    'SJ'=> ['dibenzo_ac_ah_antracen',"pesticides and industrial by products"],
    'SK'=> ['benzo_ghi_perylen',"pesticides and industrial by products"],
    'SL'=> ['antanthrene',"pesticides and industrial by products"],
    'SM'=> ['coronene',"pesticides and industrial by products"],
    'SN'=> ['dibenz_ae_pyrene',"pesticides and industrial by products"],
    'SO'=> ['dibenz_ai_pyrene',"pesticides and industrial by products"],
    'SP'=> ['dibenz_ah_pyrene',"pesticides and industrial by products"],
    'SQ'=> ['SCCP',"pesticides and industrial by products"],
    'SR'=> ['MCCP',"pesticides and industrial by products"],
    'SS'=> ['siloxane_D5',"pesticides and industrial by products"],
    'ST'=> ['Nonylphenol',"pesticides and industrial by products"], #nonPH
    'SU'=> ['Octaphenol',"pesticides and industrial by products"],  #octPH
    'SV'=> ['Z135TriCHLB',"pesticides and industrial by products"],
    'SW'=> ['Z123TriCHLB',"pesticides and industrial by products"],
    'SX'=> ['Z124TriCHLB',"pesticides and industrial by products"],
    'SY'=> ['Z2378_TCDD',"pesticides and industrial by products"],
    'SZ'=> ['Z12378_PeCDD',"pesticides and industrial by products"],
    'TA'=> ['Z123478_HxCDD',"pesticides and industrial by products"],
    'TB'=> ['Z123678_HxCDD',"pesticides and industrial by products"],
    'TC'=> ['Z123789_HxCDD',"pesticides and industrial by products"],
    'TD'=> ['Z1234678_HpCDD',"pesticides and industrial by products"],
    'TE'=> ['OCDF',"pesticides and industrial by products"],
    'TF'=> ['OCDD',"pesticides and industrial by products"],
    'TG'=> ['Z2378_TCDF',"pesticides and industrial by products"],
    'TH'=> ['Z12378_12348_PeCDF',"pesticides and industrial by products"],
    'TI'=> ['Z23478_PeCDF',"pesticides and industrial by products"],
    'TJ'=> ['Z123478_123479_HxCDF',"pesticides and industrial by products"],
    'TK'=> ['Z123678_HxCDF',"pesticides and industrial by products"],
    'TL'=> ['Z123789_HxCDF',"pesticides and industrial by products"],
    'TM'=> ['Z234678_HxCDF',"pesticides and industrial by products"],
    'TN'=> ['Z1234678_HpCDF',"pesticides and industrial by products"],
    'TO'=> ['Z1234789_HpCDF',"pesticides and industrial by products"],
    'TP'=> ['TiBP',"organophosphates (OP)"],
    'TQ'=> ['TCEP',"organophosphates (OP)"],
    'TR'=> ['TCPP',"organophosphates (OP)"],
    'TS'=> ['TDCPP',"organophosphates (OP)"],
    'TT'=> ['TBEP',"organophosphates (OP)"],
    'TU'=> ['TEHP',"organophosphates (OP)"],
    'TV'=> ['TPhP',"organophosphates (OP)"],
    'TW'=> ['EHDPP',"organophosphates (OP)"],
    'TX'=> ['ToCrP',"organophosphates (OP)"],
    'TY'=> ['TCrP',"organophosphates (OP)"],
    'TZ'=> ['DBPhP',"organophosphates (OP)"],
    'UA'=> ['DPhBP',"organophosphates (OP)"],
    'UB'=> ['MeHg',"heavy metals"],
    'UC'=> ['Hg',"heavy metals"],
    'UD'=> ['CN_33_34_37',"pesticides and industrial by products"],
    'UE'=> ['CN_47',"pesticides and industrial by products"],
    'UF'=> ['CN_28_43',"pesticides and industrial by products"],
    'UG'=> ['CN_32',"pesticides and industrial by products"],
    'UH'=> ['CN_35',"pesticides and industrial by products"],
    'UI'=> ['CN_52_60',"pesticides and industrial by products"],
    'UJ'=> ['CN_58',"pesticides and industrial by products"],
    'UK'=> ['CN_61',"pesticides and industrial by products"],
    'UL'=> ['CN_57',"pesticides and industrial by products"],
    'UM'=> ['CN_62',"pesticides and industrial by products"],
    'UN'=> ['CN_53',"pesticides and industrial by products"],
    'UO'=> ['CN_59',"pesticides and industrial by products"],
    'UP'=> ['CN_63',"pesticides and industrial by products"],
    'UQ'=> ['CN_64_68',"pesticides and industrial by products"],
    'UR'=> ['CN_65',"pesticides and industrial by products"],
    'US'=> ['CN_66_67',"pesticides and industrial by products"],
    'UT'=> ['CN_69',"pesticides and industrial by products"],
    'UU'=> ['CN_71_72',"pesticides and industrial by products"],
    'UV'=> ['CN_73',"pesticides and industrial by products"],
    'UW'=> ['CN_74',"pesticides and industrial by products"],
    'UX'=> ['Z1357_TeCN',"pesticides and industrial by products"],
    'UY'=> ['Z1256_TeCN',"pesticides and industrial by products"],
    'UZ'=> ['Z2367_TeCN',"pesticides and industrial by products"],
    'VA'=> ['Z12357_PeCN',"pesticides and industrial by products"],
    'VB'=> ['Z12367_PeCN',"pesticides and industrial by products"],
    'VC'=> ['Z12358_PeCN',"pesticides and industrial by products"],
    'VD'=> ['Z123467_HxCN_123567_HxCN',"pesticides and industrial by products"],
    'VE'=> ['Z123568_HxCN',"pesticides and industrial by products"],
    'VF'=> ['Z124568_HxCN_124578_HxCN',"pesticides and industrial by products"],
    'VG'=> ['Z123678_HxCN',"pesticides and industrial by products"],
    'VH'=> ['Z1234567_HpCN',"pesticides and industrial by products"],
    'VI'=> ['Z1234568_HpCN',"pesticides and industrial by products"],
    'VJ'=> ['TCN',"pesticides and industrial by products"],
    'VK'=> ['Z1245_TeCBz',"pesticides and industrial by products"],
    'VL'=> ['Z1234_TeCBz',"pesticides and industrial by products"],
    'VM'=> ['HxCBz',"pesticides and industrial by products"],
    'VN'=> ['PnCBz',"pesticides and industrial by products"],
    'VO'=> ['TCPM',"pesticides and industrial by products"],
    'VP'=> ['BB101',"brominated flame retardants (BFRs)"],
    'VS'=> ['CHB_40_41',"pesticides and industrial by products"],
    'VW'=> ['op_DDT_pp_DDD',"pesticides and industrial by products"],
    'VX'=> ['PCB_74_76',"polychlorinated biphenyls (PCBs)"],
    'VY'=> ['PCB_128_167',"polychlorinated biphenyls (PCBs)"],
    'WA'=> ['dibenzo_ah_antracene',"pesticides and industrial by products"],
    'WB'=> ['V6',"organophosphates (OP)"],
    'WE'=> ['DDE',"pesticides and industrial by products"],
    'WG'=> ['PFDcS',"poly- and perfluoroalkyl subtances (PFAS)"],
    'WM'=> ['B8_1414_B8_1945',"pesticides and industrial by products"],
    'WN'=> ['Z4_MeO_HpCS',"metabolized pesticides and industrial by products"],
    'WO'=> ['Z4_MeO_CB104',"metabolized polychlorinated biphenyls (PCBs)"],
    'WP'=> ['Z4_MeO_CB146',"metabolized polychlorinated biphenyls (PCBs)"],
    'WQ'=> ['Z3_MeO_CB85',"metabolized polychlorinated biphenyls (PCBs)"],
    'WR'=> ['Z4_MeO_CB120',"metabolized polychlorinated biphenyls (PCBs)"],
    'WS'=> ['Z4_MeO_CB112',"metabolized polychlorinated biphenyls (PCBs)"],
    'WT'=> ['Z4_MeO_CB107',"metabolized polychlorinated biphenyls (PCBs)"],
    'WU'=> ['Z4_MeO_CB165',"metabolized polychlorinated biphenyls (PCBs)"],
    'WV'=> ['Z3_MeO_CB138',"metabolized polychlorinated biphenyls (PCBs)"],
    'WW'=> ['Z4_MeO_CB130',"metabolized polychlorinated biphenyls (PCBs)"],
    'WX'=> ['Z4_MeO_CB187',"metabolized polychlorinated biphenyls (PCBs)"],
    'WY'=> ['Z4_MeO_CB159',"metabolized polychlorinated biphenyls (PCBs)"],
    'WZ'=> ['Z3_MeO_CB180',"metabolized polychlorinated biphenyls (PCBs)"],
    'XA'=> ['Z4_MeO_CB193',"metabolized polychlorinated biphenyls (PCBs)"],
    'XB'=> ['unidentified_MeSO2_Cl6_PCB',"metabolized pesticides and industrial by products"],
    'XE'=> ['sum_PCB',"polychlorinated biphenyls (PCBs)"],
    'XF'=> ['sum_DDT',"pesticides and industrial by products"],
    'XG'=> ['Pb',"heavy metals"],
    'XH'=> ['Cd',"heavy metals"],
    'XI'=> ['Cu',"heavy metals"],
    'XJ'=> ['Zn',"heavy metals"],
    'XK'=> ['Se',"heavy metals"],
    'XL'=> ['As',"heavy metals"],
    'XM'=> ['Z6_MeO_BDE47_2_MeO_BDE75',"metabolized brominated flame retardants (BFRs)"],
   'XN'=> ['Z5_MeO_BDE100',"metabolized brominated flame retardants (BFRs)"],
   'XO'=> ['Z4_MeO_BDE103',"metabolized brominated flame retardants (BFRs)"],
   'XP'=> ['Z5_MeO_BDE99',"metabolized brominated flame retardants (BFRs)"],
   'XQ'=> ['Z4_MeO_BDE101',"metabolized brominated flame retardants (BFRs)"],
   'XZ'=> ['DPhT_B',"pesticides and industrial by products"],
   'YA'=> ['TPhT_B',"pesticides and industrial by products"],
   'YB'=> ['MBT_B',"pesticides and industrial by products"],
   'YC'=> ['DBT_B',"pesticides and industrial by products"],
   'YD'=> ['TBT_B',"pesticides and industrial by products"],
   'YE'=> ['MPhT_B',"pesticides and industrial by products"],
   'YF'=> ['Cr',"heavy metals"],
   'YG'=> ['Ni',"heavy metals"],
   'YH'=> ['Co',"heavy metals"],
   'YL'=> ['CS_137',"radioactive compounds"],
   'YM'=> ['K_40',"radioactive compounds"],
   'YO'=> ['Nonylphenol',"pesticides and industrial by products"],
   'YP'=> ['Octaphenol',"pesticides and industrial by products"],
   'YQ'=> ['Z4_MeSO2_CB110_4_MeSO2_CB87','metabolized polychlorinated biphenyls (PCBs)'],
   'YS'=> ['CHB_2',"pesticides and industrial by products"],
   'YT'=> ['CHB_42',"pesticides and industrial by products"],
   'YU'=> ['TPrP',"organophosphates (OP)"],
   'YV'=> ['BdPhP',"organophosphates (OP)"],
   'YW'=> ['TPP',"organophosphates (OP)"],
   'YX'=> ['TnBP',"organophosphates (OP)"],
   'YY'=> ['ToCrP',"organophosphates (OP)"],
   'YZ'=> ['EHDP',"organophosphates (OP)"],
   'ZA'=> ['TXP',"organophosphates (OP)"],
   'ZB'=> ['TIPPP',"organophosphates (OP)"],
   'ZC'=> ['TTBPP',"organophosphates (OP)"],
   'ZD'=> ['DMP',"phtalates"],
   'ZE'=> ['DEP',"phtalates"],
   'ZF'=> ['DiBP',"phtalates"],
   'ZG'=> ['DnBP',"phtalates"],
   'ZH'=> ['BBP',"phtalates"],
   'ZI'=> ['DCHP',"phtalates"],
   'ZJ'=> ['DMPP',"phtalates"],
   'ZK'=> ['DHxP',"phtalates"],
   'ZL'=> ['DEHP',"phtalates"],
   'ZM'=> ['DOP',"phtalates"],
   'ZN'=> ['DiNP',"phtalates"],
   'ZO'=> ['DNP',"phtalates"],
   'ZP'=> ['DiDCP',"phtalates"],
   'ZQ'=> ['TEP',"organophosphates (OP)"],
   'ZR'=> ['PFPS',"poly- and perfluoroalkyl subtances (PFAS)"],
   'ZT'=> ['PFPA',"poly- and perfluoroalkyl subtances (PFAS)"],
   'ZU'=> ['PFDcA',"poly- and perfluoroalkyl subtances (PFAS)"],
   'ZW'=> ['tn_CHL_MC6',"pesticides and industrial by products"],
   'ZX'=> ['Z4_MeO_CB79',"metabolized polychlorinated biphenyls (PCBs)"],
   'ZY'=> ['Z4_Meo_CB101',"metabolized polychlorinated biphenyls (PCBs)"],
   'ZZ'=> ['Z2_MeO_CB114',"metabolized polychlorinated biphenyls (PCBs)"],
   'AAA'=> ['Z3_MeO_CB182',"metabolized polychlorinated biphenyls (PCBs)"],
   'AAB'=> ['Z3_MeO_CB183',"metabolized polychlorinated biphenyls (PCBs)"],
   'AAC'=> ['Z4_MeO_CB97',"metabolized polychlorinated biphenyls (PCBs)"],
   'AAD'=> ['Z4_MeO_CB200',"metabolized polychlorinated biphenyls (PCBs)"],
   'AAE'=> ['Z44_diMeO_CB202',"metabolized polychlorinated biphenyls (PCBs)"],
   'AAF'=> ['Z4_MeO_CB127',"metabolized polychlorinated biphenyls (PCBs)"],
   'AAG'=> ['Z4_MeO_CB201',"metabolized polychlorinated biphenyls (PCBs)"],
   'AAH'=> ['Z3_MeO_CB203_4_MeO_CB198',"metabolized polychlorinated biphenyls (PCBs)"],
   'AAI'=> ['Z2_MeO_BDE66',"metabolized brominated flame retardants (BFRs)"],
   'AAK'=> ['Z6_MeO_BDE90_6MeO_BDE99',"pesticides and industrial by products"],
   'AAL'=> ['Z6_OH_BDE99',"metabolized brominated flame retardants (BFRs)"],
   'AAM'=> ['PBP',"metabolized brominated flame retardants (BFRs)"],
   'AAN' => ['PCB_128',"polychlorinated biphenyls (PCBs)"]  #sum_ar_1260
  };


    biomarker_arr = {
    "WC" => ["cholesterol","metabolites"],
    "WD"=> ["triglycerides","metabolites"],
    "XX" => ["retinol","vitamins"],
    "XY" => ["retinyl_palmitate","vitamins"],
    "YJ" => ["testosterone_6B","hormones"],
    "XR" => ["uro_porphyrin","metabolites"],
    "XS" => ["hepta_porphyrin","metabolites"],
    "XT"=> ["hexa_porphyrin","metabolites"],
    "XU"=> ["penta_porphyrin","metabolites"],
    "XV"=> ["copro_porphyrin","metabolites"],
    "XW"=> ["proto_porphyrin","metabolites"],
    "ZV" => ["EROD","hormones"]   #resorufin
    };

    # do work on files ending in .xls in the desired directory
    Dir.glob('./leser/*.xls*') do |excel_file|

     #Get filename -last part of array (path is the first)
     #puts excel_file
     filename =  excel_file[8..-1]

     puts filename

     #Open the file
     s = SimpleSpreadsheet::Workbook.read(excel_file)

     #Always fetch the first sheet
     s.selected_sheet = s.sheets.first

     #Start down the form -after
     line = 2

     #Set server database here
     server = Couch::Server.new(host, port)

     #Get uuid fieldwork
     uuid_fieldwork = getUUID()
     puts uuid_fieldwork

     @links = {
       :rel => 'data',
       :href => "https://api.npolar.no/ecotox/fieldwork/" + uuid_fieldwork,
       :title => "fieldwork",
       :hreflang => "no",
       :type => "application/json"
     }


     #Fetch a UUID from couchdb
     link = 'https://' + host + '/ecotox/excel/'+ s.cell(2,'R')
     res = server.gets(URI(link))
     #Extract the UUID from reply
     @excel_file = JSON.parse(res.body)

     unless @excel_file['filename']  == s.cell(2,'S')
        puts 'https://' + host + '/ecotox/excel/'+ s.cell(2,'R')
         FileUtils.mv 'leser/'+ filename, 'feilet/' + filename
        puts "error in file matching"

     else

     @files = {
       :uri => s.cell(2,'R'),
       :filename => s.cell(2,'S'),
       :title => "Original excel file",
       :type => s.cell(2,'T'),
       :length => (s.cell(2,'U')).to_i,
       :hash => @excel_file['hash']
     }

     @files_fieldwork = {
       :uri => s.cell(2,'AAP'),
       :filename => s.cell(2,'AAQ'),
       :title => "Original excel file",
       :type => s.cell(2,'AAR'),
       :length => (s.cell(2,'AAS')).to_i,
       :hash => Digest::MD5.hexdigest(filename)
     }


     @ecotox_fieldwork_entry_arr = []


     #Traverse rows
     while (line < (s.last_row).to_i + 1) && ((s.cell(line,'C') != nil) || ((s.cell(line,'G')!= nil)))
           #puts line.to_s + " line"

           database_sample_id2 = uuid_fieldwork + "-" + (line-1).to_s
           laboratory2 = laboratory(checkExistence(s.cell(line,'B')))
           date_report2 = iso8601time(checkExistence(s.cell(line,'M')))
           rightsholder2 = rightsholder(checkExistence(s.cell(line,'Q')))
           people_responsible2 = people_responsible(checkExistence(s.cell(line,'W'))+ " " + checkExistence(s.cell(line,'X'))+ " " + checkExistence(s.cell(line,'Y')))
           lab_report_id2 = (checkExistence(s.cell(line,'XD'))).to_s
           matrix2 = matrix(checkExistence(s.cell(line,'G')))
           species2 = species(s.cell(line,'C'))
           unit2 = unit(checkExistence(s.cell(line,'AB')))
           fat_percentage2 = checkExistence(s.cell(line,'K')).to_f
           #npi_sample_id2 = remove_zero(checkExistence(s.cell(line,'H')).to_s)
           npi_sample_id2 = checkExistence(s.cell(line,'H')).to_s
           lab_sample_id2 = (checkExistence(s.cell(line,'J'))).to_s

           #scull or bill + head
           scull2 = checkExistence(s.cell(line,'WK')).tr('*','')
           if scull2 == ''
            scull2 = checkExistence(s.cell(line,'YN')) +  checkExistence(s.cell(line,'WJ'))
           end



         @ecotox_fieldwork_entry = {
          :database_sample_id => database_sample_id2,
          :NPI_sample_id => npi_sample_id2,
          :project_group => s.cell(line,'A'),
          :rightsholder => rightsholder2,
          :people_responsible => people_responsible2,
          :reference => s.cell(line,'ER'),
          :event_date => iso8601time(checkExistence(s.cell(line,'L').to_s)),
          :placename => s.cell(line,'P'),
          :latitude => checkExistence(s.cell(line,'N')).to_f,
          :longitude => checkExistence(s.cell(line,'O')).to_f,
          :station_name => checkExistence(s.cell(line,'AAO')),
          :species => species2,
          :species_identification => checkExistence(s.cell(line,'I')),
          :matrix => matrix2,
          :age => checkExistence(s.cell(line,'D')) + " " + checkExistence(s.cell(line,'F')),
          :sex => sex(s.cell(line,'E')),
          :weight => (checkExistence(s.cell(line,'WH')).tr('*','')).to_f +  (checkExistence(s.cell(line,'VZ')).tr('*','')).to_f,
          :girth => (checkExistence(s.cell(line,'ZS')).tr('*','')).to_f,
          :length => (checkExistence(s.cell(line,'VQ')).tr('*','')).to_f,
          :condition => checkExistence(s.cell(line,'WF')).tr('*',''),
          :comment => s.cell(line,'V'),
          :tarsus => (((checkExistence(s.cell(line,'WL'))).tr('*','')).to_f),
          :bill => (((checkExistence(s.cell(line,'WJ'))).tr('*','')).to_f),
          :bill_height => ((checkExistence(s.cell(line,'XC')).tr('*','')).to_f),
          :scull => (scull2).to_f,
          :wing => ((checkExistence(s.cell(line,'WI')).tr('*','')).to_f),
          :egg_width => (checkExistence(s.cell(line,'AAJ')).tr('*','').to_f),
          :tusk_volume =>  ((checkExistence(s.cell(line,'VR'))).to_f),
          :tusk_length =>  ((checkExistence(s.cell(line,'VU'))).to_f),
          :tusk_girth =>  ((checkExistence(s.cell(line,'VV'))).to_f),
          :caudal_length => ((checkExistence(s.cell(line,'YR'))).to_f)
         }

         @ecotox_fieldwork_entry = removeEmpty(@ecotox_fieldwork_entry)

         #puts @ecotox_fieldwork_entry

         #Put all entries in a large array
         @ecotox_fieldwork_entry_arr.push(@ecotox_fieldwork_entry)

         #if existing, TEQ should be added to comment
         teq = checkExistence(s.cell(line,'YK'))
         (teq  == "") ? "" : "TEQ:" + s.cell(line,'YK')

        detection_limit = checkExistence(s.cell(line,'AC'))
        if (detection_limit == 'NOT IN USE')
              detection_limit = ''
        end

        percent_recovery = checkExistence(s.cell(line,'AA'))
        if (percent_recovery == 'NOT IN USE')
              percent_recovery = ''
        end

        corrected_blank_contamination = checkExistence(s.cell(line,'Z'))
        if (corrected_blank_contamination == 'NOT IN USE')
              corrected_blank_contamination = ''
        end
        comment2 = checkExistence(s.cell(line,'V')) + " " + corrected_blank_contamination + teq

        #Iterate through all analytes
        header_arr.each do | key, value |
          analyte = (checkExistence(s.cell(line,"#{key}"))).to_s


          if (analyte.length > 0)
            analyte_arr = analyte.split("*")

            #Get uuid ecotox
            uuid_ecotox = getUUID()

            @lab_ecotox = {
              :id => uuid_ecotox,
              :_id => uuid_ecotox,
              :schema => 'http://api.npolar.no/schema/lab-ecotox',
              :lang => 'no',
              :laboratory => laboratory2,
              :lab_report_id => lab_report_id2,
              :date_report =>iso8601time(checkExistence(s.cell(line,'M').to_s)),
              :rightsholder => rightsholder2,
              :people_responsible => people_responsible2,
              :matrix => matrix2,
              :species => species2,
              :database_sample_id => database_sample_id2,
              :NPI_sample_id => npi_sample_id2,
              :lab_sample_id => lab_sample_id2,
              :fat_percentage => fat_percentage2.to_f,
              :unit => unit2,
              :comment => comment2,
              :analyte_category => "#{value[1]}",
              :analyte => "#{value[0]}",
              :wet_weight => wet_weight(checkExistence(analyte_arr[0])),
              :lipid_weight => s.cell(line,'VT'),
              :detection_limit => ((detection_limit).to_f) + ((checkExistence(analyte_arr[1])).to_f),
              :recovery_percent => ((percent_recovery).to_f) +  ((checkExistence(analyte_arr[2])).to_f),
              :level_of_quantification => (analyte_arr[3].to_f),
              #:links => @links,
              :files => [@files],
              :collection => 'lab',
              :created => timestamp,
              :updated => timestamp,
              :created_by => user,
              :updated_by => user
            }


            @lab_ecotox = removeEmpty(@lab_ecotox)
            doc_ecotox = @lab_ecotox.to_json
            #puts doc_ecotox

            #post entry
            begin
             http = postToServer('https://' + host + '/lab/ecotox/'+uuid_ecotox,doc_ecotox,auth,user,password)
            ensure
             #log "Error lab-ecotox" +line.to_s
             http.finish if http.started?
            end

          end #if
          end #traverse analytes


          biomarker_arr.each do | key2, value2 |
            biomarker = checkExistence(s.cell(line,"#{key2}")).to_s

            if (biomarker.length > 0)
              #Split values
              biomarker_arr2 = biomarker.split("*")

              #Get uuid ecotox
              uuid_biomarker = getUUID()

            #Create the json structure object
            @lab_biomarker = {
              :id => uuid_biomarker,
              :_id => uuid_biomarker,
              :schema => 'http://api.npolar.no/schema/lab-biomarker',
              :lang => 'no',
              :laboratory => laboratory2,
              :date_report => s.cell(line,'M') == nil ? '' :date_report2,
              :rightsholder => rightsholder2,
              :people_responsible => people_responsible2,
              :matrix => matrix2,
              :species => species2,
              :database_sample_id => database_sample_id2,
              :NPI_sample_id => npi_sample_id2,
              :biomarker_category => "#{value2[1]}",
              :biomarker => "#{value2[0]}",
              :unit => unit2,
              :percent_recovery => biomarker_arr2[2],
              :detection_limit => biomarker_arr2[1],
              :level_of_quantification => biomarker_arr2[3],
              :comment => s.cell(line,'V'),
              :sample_values => [biomarker_arr2[0]],
              :files => [@files],
              :collection => 'lab',
              :created => timestamp,
              :updated => timestamp,
              :created_by => user,
              :updated_by => user
            }

            @lab_biomarker = removeEmpty(@lab_biomarker)
            doc_biomarker = @lab_biomarker.to_json
            #puts doc_biomarker
            #post entry
            begin
              http = postToServer('https://' + host + '/lab/biomarker/'+uuid_biomarker,doc_biomarker,auth,user,password)
            ensure
              #puts "Error ecotox-biomarker" + line.to_s
              http.finish if http.started?
            end
          end #if
          end #traverse analytes

          #Count up next line
          line += 1
     end #while line


     #Create the json structure object
     @ecotox_fieldwork = {
       :id => uuid_fieldwork,
       :_id => uuid_fieldwork,
       :schema => 'http://api.npolar.no/schema/ecotox-fieldwork',
       :lang => 'no',
       :entry => @ecotox_fieldwork_entry_arr,
       :files => (s.cell(2,'AAP')) == nil ? [@files] : [@files_fieldwork],
       :collection => 'ecotox-fieldwork',
       :created => timestamp,
       :updated => timestamp,
       :created_by => user,
       :updated_by => user
     }


    #puts @ecotox_fieldwork.to_json
    doc_fieldwork = @ecotox_fieldwork.to_json
    #puts doc_fieldwork

    #post entry
    begin
     http = postToServer('https://' + host + '/ecotox/fieldwork/'+uuid_fieldwork,doc_fieldwork,auth,user,password)
   ensure
     #puts "error ecotox-fieldwork"
     http.finish if http.started?
   end
     FileUtils.mv 'leser/'+ filename, 'done/' + filename

  end #file
end #file not match
  end
  #http.finish
end
