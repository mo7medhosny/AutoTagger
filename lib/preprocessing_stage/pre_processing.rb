#encoding: utf-8
require 'preprocessing_stage/trie'

class PreprocessingStage::PreProcessing
include LinkProbability

def self.test
DB.run_queries [INSERT_ANCHOR_DATA_INTO_PROP_TABLE%["ali",2]]
end

def self.callLinkProbability
  puts "Start linkProbabilityTable"
  
  puts "Start calculate_link_occure"
  link_occure=PreprocessingStage::LinkProbability.calculate_link_occure #label:{[label,title] => #OfOccur}
  puts "End calculate_link_occure"
  
  labels=[]
  link_occure.each do |key,val|
    if (key[0] != nil && key[0].size >0)
      labels << key[0]
    end  
  end

  puts "Start calculate_text_occure"
  text_occure=PreprocessingStage::LinkProbability.calculate_text_occure labels #{text =>#OfOccur}
  #call calculate_text_occure functions with teh keys stored in array
  puts "End calculate_text_occure"
  
  puts "Start save_link_probability_table"
  save_link_probability_table link_occure,text_occure
  puts "End save_link_probability_table"
  
end

def self.save_link_probability_table link,text
  ActiveRecord::Base.connection.execute("
  create table link_prop_tmp(
  label VARCHAR(255) NOT NULL,
  page_title VARCHAR(255) NOT NULL,
  text_occure MEDIUMINT UNSIGNED NOT NULL DEFAULT 0,
  link_occure MEDIUMINT UNSIGNED NOT NULL DEFAULT 0,
  KEY(page_title)
  ) DEFAULT CHARSET=utf8;
  ")
  link.each do |key, val|
  if (text[key[0]] == nil)
    text[key[0]]=0
  end
  ActiveRecord::Base.connection.execute("
  INSERT IGNORE INTO link_prop_tmp(label, page_title, text_occure, link_occure) 
  VALUES (\"#{key[0]}\",\"#{key[1]}\",#{text[key[0]]},#{val});
  ")
  end
end

 def self.synonymsFirstJoin
    results = 
        ActiveRecord::Base.connection.execute(" select rd_from , rd_title , page_id
            from redirect
            inner join page 
            on page_namespace = 0 and  rd_title = page_title
            ORDER BY rd_from ;")
    results.each do |r|
    p = r[1].strip.gsub("\""," ").force_encoding('utf-8')
    ActiveRecord::Base.connection.execute("insert into Synonyms1 values (#{r[0]}, \"#{p}\"  , #{r[2]});")
    end        
  end   
  
  
   def self.synonymsSecondtJoin
    results = 
        ActiveRecord::Base.connection.execute(" select * from Synonyms1;")
    results.each do |r| 
            results2 = ActiveRecord::Base.connection.execute(" select page_title from page where page_id = #{r[0]};")
            p = r[1].strip.gsub("\""," ").force_encoding('utf-8')
            results2.each do |r2|
                 p2 = r2[0].strip.gsub("\""," ").force_encoding('utf-8')
                 p2 = p2.strip.gsub("\\"," ").force_encoding('utf-8')
                 ActiveRecord::Base.connection.execute("insert into Synonyms2 values (#{r[0]}, \"#{p2}\",\"#{p}\"  , #{r[2]});")
        end
    end        
  end   
  
  def self.extractDisambiguation
    results = ActiveRecord::Base.connection.execute(" select page_id , page_title from page where page_namespace = 0 ;")
     results.each do |r|
      p_title = r[1].strip.gsub("\""," ").force_encoding('utf-8')
      if p_title.include? "توضيح"
        # checkExist = ActiveRecord::Base.connection.execute(" select page_title from Disambiguation  where page_title=\"#{p_title}\" ;")
         # if checkExist.size==0
            results2 = ActiveRecord::Base.connection.execute(" select pl_title from pagelinks where pl_from = #{r[0]} and pl_namespace = 0;")
            results2.each do |r2|
                 pl_title = r2[0].strip.gsub("\""," ").force_encoding('utf-8')
                 pl_title = pl_title.strip.gsub("\\"," ").force_encoding('utf-8')
                 ActiveRecord::Base.connection.execute("insert into Disambiguation values (#{r[0]}, \"#{p_title}\",\"#{pl_title}\");")
            end
        # end      
      end 
    end
    
 end 

end