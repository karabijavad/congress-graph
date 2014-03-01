require 'cadet'
require 'yaml'
require 'json'

db = Cadet::Session.open("neo4j-community-2.0.1/data/graph.db").dsl do

  transaction do
    constraint :Legislator, :thomas_id
    constraint :Bill,       :id
    constraint :Gender,     :name
    constraint :Religion,   :name
    constraint :Party,      :name
    constraint :State,      :name
    constraint :Role,       :name
    constraint :District,   :district
    constraint :Subject,    :name
    constraint :Committee,  :thomas_id
  end

  puts "loading legislators"
  YAML.load_file('data/congress-legislators/legislators-current.yaml').each do |leg|
    transaction do
      l = create_Legislator_on_thomas_id({
          thomas_id: leg["id"]["thomas"].to_i,
          gender:    leg["bio"]["gender"],
          name:      "#{leg['name']['first']} #{leg['name']['last']}"
      })

      l.religion_to Religion_by_name(leg["bio"]["religion"]) if leg["bio"]["religion"]

      leg["terms"].each do |term|
        t = create_node_with(:Term, {:role => term["type"], :start => term["start"].gsub(/-/, '').to_i, :end => term["end"].gsub(/-/, '').to_i})

        t.party_to      Party_by_name(term["party"])
        t.represents_to State_by_name(term["state"])

        l.term_to t
      end

      leg["terms"].map { |term| term["party"]}.each do |party|
         l.hyper_party_to Party_by_name(party)
      end
    end
  end

  puts "loading committees"
  YAML.load_file('data/congress-legislators/committees-current.yaml').each do |committee_data|
    transaction do
      committee = create_Committee_on_thomas_id({
        name:         committee_data["name"],
        thomas_id:    committee_data["thomas_id"]
      })

      if subcommittees = committee_data["subcommittees"]
        subcommittees.each do |subcommittee_data|
          committee.subcommittee_to create_Committee_on_thomas_id({
            name:         subcommittee_data["name"],
            thomas_id:    "#{committee_data['thomas_id']}#{subcommittee_data['thomas_id']}"
          })
        end
      end
    end
  end

  puts "loading committee memberships"
  YAML.load_file('data/congress-legislators/committee-membership-current.yaml').each do |committee_data|
    transaction do
      c = Committee_by_thomas_id committee_data[0].to_s

      committee_data[1].each do |leg|
        c.member_to Legislator_by_thomas_id(leg["thomas"].to_i)
      end
    end
  end

  puts "loading bills"
  file_queue = Queue.new
  data_queue = SizedQueue.new(16)
  Thread.abort_on_exception = true

  1.upto(8).map do
    Thread.new do
      while json_file = file_queue.pop rescue nil
        data_queue << JSON.parse(File.read(json_file))
      end
    end
  end

  Dir['data/congress-data/*/bills/*/*/*.json'].each { |f| file_queue.push f }

  until file_queue.empty? && data_queue.empty?
    transaction do
      bill_data = data_queue.pop

      bill = create_Bill_on_id({
        id:             bill_data["bill_id"],
        official_title: bill_data["official_title"].to_s,
        summary:        (bill_data["summary"] && bill_data["summary"]["text"].to_s) || ""
       })

      bill.congress_to Congress_by_number(bill_data["congress"].to_i)

      if sponsor = bill_data["sponsor"]
        bill.sponsor_to Legislator_by_thomas_id(sponsor["thomas_id"].to_i)
      end

      bill_data["cosponsors"].each do |cosponsor|
         bill.cosponsor_to Legislator_by_thomas_id(cosponsor["thomas_id"].to_i)
      end

      bill_data["subjects"].each do |subject|
        bill.subject_to Subject_by_name(subject)
      end
      bill.subject_top_term_to Subject_by_name(bill_data["subjects_top_term"]) if bill_data["subjects_top_term"]
    end
  end
end

puts "closing database"

db.close

puts "database closed"
