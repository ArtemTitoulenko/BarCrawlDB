class Hash
  def keys_to_sym(*keys)
    self.keys.each do |key|
      self[key.to_sym] = self[key]
      self.delete key
    end
    return self
  end
end

class String
  def db_norm
    self.gsub("'", "''")
  end
end

def irand(limit=1)
  return rand(limit).round
end

# create database and use it
def init_database(client)
  return unless client.is_a? Mysql2::Client

  client.query('drop database barcrawldb;')

  client.query('CREATE DATABASE IF NOT EXISTS barcrawldb;')
  client.query('USE barcrawldb;')
end

# create tables
def init_tables(client)
  return unless client.is_a? Mysql2::Client

  # drinker table
  client.query('CREATE TABLE IF NOT EXISTS `drinker` (
    `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
    `name` text NOT NULL,
    `address` text NOT NULL,
    `age` int(11) unsigned NOT NULL,
    `company_id` int(11) unsigned NOT NULL,
    PRIMARY KEY (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8;')

  # sells table
  client.query('CREATE TABLE IF NOT EXISTS `sells` (
    `bar_id` int(11) unsigned NOT NULL,
    `beer_id` int(11) unsigned NOT NULL,
    `price` int(11) unsigned NOT NULL
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8;')

  # bar table
  client.query('CREATE TABLE IF NOT EXISTS `bar` (
    `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
    `name` text NOT NULL,
    `address` text NOT NULL,
    PRIMARY KEY (`id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8;')

  # buys table
  client.query('CREATE TABLE IF NOT EXISTS `buys` (
    `bar_id` int(11) unsigned NOT NULL,
    `drinker_id` int(11) unsigned NOT NULL,
    `beer_id` int(11) unsigned NOT NULL,
    `quantity` int(11) unsigned NOT NULL,
    `date` float NOT NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8;')

  # beer table
  client.query('CREATE TABLE IF NOT EXISTS `beer` (
    `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
    `name` text NOT NULL,
    `manf` text NOT NULL,
    `recyclable` tinyint(1) NOT NULL,
    PRIMARY KEY (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8;')

  # company table
  client.query('CREATE TABLE IF NOT EXISTS `company` (
    `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
    `name` text NOT NULL,
    `address` text NOT NULL,
    PRIMARY KEY (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8;')
end

def insert_company(client, company)
  query = "insert into company (name, address)
    values ('#{company.name.db_norm}', '#{company.address.to_s}');"
  client.query(query)
end

def insert_drinkers(client, drinkers)
  query = "insert into drinker (name, address, age, company_id)
    values "
  query << drinkers.map { |drinker|
      "('#{drinker.name.db_norm}', '#{drinker.address.to_s}', '#{drinker.age}', '#{drinker.company_id}')"
    }.join(",") + ";"
  client.query(query)
end

def insert_beer(client, beer)
  query = "insert into beer (name, manf, recyclable)
    values ('#{beer.name.db_norm}', '#{beer.manf}', '#{beer.recyclable ? 1 : 0}');"
  client.query(query)
end

def insert_bar(client, bar)
  query = "insert into bar (name, address)
    values ('#{bar.name.db_norm}', '#{bar.address.to_s}');"
  client.query(query)
end

def insert_beer_sale(client, bar, beer, price)
  query = "insert into sells (bar_id, beer_id, price)
    values ('#{bar.id}', '#{beer.id}', '#{price}');"
  client.query(query)
end

def insert_purchases(client, purchases)
  query = "insert into buys (bar_id, drinker_id, beer_id, quantity, date)
    values"
  query << purchases.map { |buy|
      "('#{buy.bar_id}', '#{buy.person_id}', '#{buy.beer_id}', '#{buy.quantity}', '#{buy.date}')"
    }.join(",") + ";"
  client.query(query)
end
