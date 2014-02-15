require 'cadet'
require 'yaml'
require 'json'

db = Cadet::BatchInserter::Session.open("neo4j-community-2.0.1/data/graph.db")

db.transaction do
  db.constraint "Legislator", "name"
  db.constraint "Legislator", "thomas_id"
  db.constraint "Bill", "id"
  db.constraint "Gender", "name"
  db.constraint "Religion", "name"
  db.constraint "Party", "name"
  db.constraint "State", "name"
  db.constraint "Role", "name"
end

YAML.load_file('data/congress-legislators/legislators-current.yaml').each do |leg|
  db.transaction do
    l = db.get_node "Legislator", "thomas_id", leg["id"]["thomas"].to_i

    if leg["bio"]["gender"]
      gender = db.get_node "Gender", "name", leg["bio"]["gender"]
      l.outgoing("gender") << gender
    end

    if leg["bio"]["religion"]
      religion = db.get_node "Religion", "name", leg["bio"]["religion"]
      l.outgoing("religion") << religion
    end

    leg["terms"].each do |term|
      t = db.create_node("Term", "start", term["start"][0...4].to_i)

      party = db.get_node "Party", "name", term["party"]
      t.outgoing("party")      << party

      state = db.get_node "State", "name", term["state"]
      t.outgoing("represents") << state

      role = db.get_node "Role", "name", term["type"]
      t.outgoing("role")       << role

      l.outgoing("term") << t
    end

  end
end

Dir['data/congress-data/*/bills/*/*/*.json'].each do |json_file|
  bill_data = JSON.parse(File.read(json_file))
  db.transaction do |tx|
    begin
      bill = db.get_node "Bill", "id", bill_data["bill_id"]
      bill["official_title"] = bill_data["official_title"].to_s

      sponsor = db.get_node "Legislator", "thomas_id", bill_data["sponsor"]["thomas_id"].to_i
      bill.outgoing("sponsor") << sponsor

      congress = db.get_node "Congress", "number", bill_data["congress"].to_i
      bill.outgoing("congress") << congress

      bill_data["cosponsors"].each do |cosponsor|
        cosponsor = db.get_node "Legislator", "thomas_id", cosponsor["thomas_id"].to_i
        bill.outgoing("cosponsor") << cosponsor
      end
    rescue Exception => e
      # tx.failure
    end
  end
end

db.close
