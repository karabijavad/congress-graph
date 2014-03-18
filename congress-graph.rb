require 'cadet'
require 'yaml'
require 'json'

Cadet::BatchInserter::Session.open "neo4j-community-2.0.1/data/graph.db" do

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
      l = Legislator_by_thomas_id(leg["id"]["thomas"].to_i)
      l[:gender] = leg["bio"]["gender"]
      l[:name]   = "#{leg['name']['first']} #{leg['name']['last']}"

      l.religion_to Religion_by_name(leg["bio"]["religion"]) if leg["bio"]["religion"]

      leg["terms"].each do |term|
        t = create_Term({:role => term["type"], :start => term["start"].gsub(/-/, '').to_i, :end => term["end"].gsub(/-/, '').to_i})

        t.party_to      Party_by_name(term["party"])
        t.represents_to State_by_name(term["state"])

        l.term_to t
      end

      leg["terms"].map { |term| term["party"]}.uniq.each do |party|
         l.hyper_party_to Party_by_name(party)
      end
    end
  end

  puts "loading committees"
  YAML.load_file('data/congress-legislators/committees-current.yaml').each do |committee_data|
    transaction do
      committee = Committee_by_thomas_id(committee_data["thomas_id"])
      committee[:name] = committee_data["name"]

      if committee_data["subcommittees"]
        committee_data["subcommittees"].each do |subcommittee_data|
          sc = Committee_by_thomas_id("#{committee_data['thomas_id']}#{subcommittee_data['thomas_id']}")
          committee.subcommittee_to sc
          sc[:name] = subcommittee_data["name"]
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
  data_queue = SizedQueue.new(100)
  Thread.abort_on_exception = true

  1.upto(32).map do
    Thread.new do
      while json_file = file_queue.pop rescue nil
        data_queue << JSON.parse(File.read(json_file))
      end
    end
  end

  Dir['data/congress-data/{109,110,111,112,113}/bills/*/*/*.json'].each { |f| file_queue.push f }

  until file_queue.empty? && data_queue.empty?
    transaction do
      bill_data = data_queue.pop

      bill = Bill_by_id bill_data["bill_id"]
      bill[:official_title] = bill_data["official_title"].to_s
      bill[:summary]        = bill_data["summary"]["text"].to_s if bill_data["summary"]

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
