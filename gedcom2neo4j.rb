#!/usr/bin/ruby 
 

require 'rubygems'
require 'neography'
require 'gedcom'



if ARGV.length < 1
  puts "Usage: #{File.basename(__FILE__)} <gedcomfile>"
  exit(0)
end

@gedcom = ARGV[0]
@parser = GedcomParser.new

lineno = 0
File.new(@gedcom).each_line do |line|
  next if line =~ /geni:/
  next if line =~ /_EMAIL/
  next if line =~ /PHON/
  next if line =~ /_MAR/
  lineno = lineno +1
  @parser.parse(lineno, line)
end

@parser.summary()

@neo = Neography::Rest.new


@persons = Hash.new
@parser.transmission.individual_record.each do |person|
  node = Neography::Node.create
  node[:FIRST_NAME] = person.name_record[0].given[0][0]
  node[:LAST_NAME] = person.name_record[0].surname[0][0] if not person.name_record[0].surname.nil?
  if person.death
	node[:DESEASED] = :yes
  end
  person.individual_attribute_record.each do |r|
	next if r.attr_type[0] != "SEX"
	value = r.value[0][0] # Using first sex
	if value == "M" || value == "F"
	  node[:SEX] = value
	end
  end
  @persons[person.individual_ref[0][1]] = node
end


@parser.transmission.family_record.each do |family|
  if not family.husband_ref.nil? and not family.wife_ref.nil?
	snode1 = @persons[family.husband_ref[0][1]]
	snode2 = @persons[family.wife_ref[0][1]]
	snode1.outgoing(:SPOUSE) << snode2
	snode1.incoming(:SPOUSE) << snode2
  end
  if not family.child_ref.nil? and (not family.husband_ref.nil? or not family.wife_ref.nil?)
	family.child_ref.each do |cr|
	  cnode =  @persons[cr[1]]
	  if not family.husband_ref.nil? 
		pnode = @persons[family.husband_ref[0][1]]
		pnode.outgoing(:CHILD) << cnode
		pnode.incoming(:PARENT) << cnode
	  end
	  if not family.wife_ref.nil? 
		pnode = @persons[family.wife_ref[0][1]]
		pnode.outgoing(:CHILD) << cnode
		pnode.incoming(:PARENT) << cnode
	  end
	end
  end
end
