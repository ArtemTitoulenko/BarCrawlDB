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

  client.query('drop database if exists barcrawldb;')

  client.query('CREATE DATABASE IF NOT EXISTS barcrawldb;')
  client.query('USE barcrawldb;')
end

# create tables
def init_tables(client)
  return unless client.is_a? Mysql2::Client

  # bar table
  client.query('CREATE TABLE IF NOT EXISTS `bar` (
    `id` int(11) unsigned NOT NULL,
    `name` text NOT NULL,
    `address` text NOT NULL,
    PRIMARY KEY (`id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8;')

  # beer table
  client.query('CREATE TABLE IF NOT EXISTS `beer` (
    `id` int(11) unsigned NOT NULL,
    `name` text NOT NULL,
    `manf` text NOT NULL,
    `recyclable` tinyint(1) NOT NULL,
    PRIMARY KEY (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8;')

  # company table
  client.query('CREATE TABLE IF NOT EXISTS `company` (
    `id` int(11) unsigned NOT NULL,
    `name` text NOT NULL,
    `address` text NOT NULL,
    PRIMARY KEY (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8;')

  # drinker table
  client.query('CREATE TABLE `drinker` (
    `id` int(11) unsigned NOT NULL,
    `name` text NOT NULL,
    `address` text NOT NULL,
    `age` int(11) unsigned NOT NULL,
    `company_id` int(11) unsigned NOT NULL,
    PRIMARY KEY (`id`),
    KEY `company_id` (`company_id`),
    CONSTRAINT `drinker_ibfk_1` FOREIGN KEY (`company_id`) REFERENCES `company` (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8;')

  # sells table
  client.query('CREATE TABLE `sells` (
    `bar_id` int(11) unsigned NOT NULL,
    `beer_id` int(11) unsigned NOT NULL,
    `price` int(11) unsigned NOT NULL,
    KEY `bar_id` (`bar_id`),
    KEY `beer_id` (`beer_id`),
    CONSTRAINT `sells_ibfk_2` FOREIGN KEY (`beer_id`) REFERENCES `beer` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
    CONSTRAINT `sells_ibfk_1` FOREIGN KEY (`bar_id`) REFERENCES `bar` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8;')

  # buys table
    client.query('CREATE TABLE `buys` (
    `bar_id` int(11) unsigned NOT NULL,
    `drinker_id` int(11) unsigned NOT NULL,
    `beer_id` int(11) unsigned NOT NULL,
    `quantity` int(11) unsigned NOT NULL,
    `day` int(11) unsigned NOT NULL,
    `bar_number` int(11) unsigned NOT NULL,
    `week_number` int(11) unsigned NOT NULL,
    KEY `bar_id` (`bar_id`),
    KEY `drinker_id` (`drinker_id`),
    KEY `beer_id` (`beer_id`),
    CONSTRAINT `buys_ibfk_3` FOREIGN KEY (`beer_id`) REFERENCES `beer` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
    CONSTRAINT `buys_ibfk_1` FOREIGN KEY (`bar_id`) REFERENCES `bar` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
    CONSTRAINT `buys_ibfk_2` FOREIGN KEY (`drinker_id`) REFERENCES `drinker` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8;')
end

def insert_company(client, company)
  query = "insert into company (id, name, address)
    values ('#{company.id}','#{company.name.db_norm}', '#{company.address.to_s}');"
  client.query(query)
end

def insert_drinkers(client, drinkers)
  query = "insert into drinker (id, name, address, age, company_id)
    values "
  query << drinkers.map { |drinker|
      "('#{drinker.id}','#{drinker.name.db_norm}', '#{drinker.address.to_s}', '#{drinker.age}', '#{drinker.company_id}')"
    }.join(",") + ";"
  client.query(query)
end

def insert_beer(client, beer)
  query = "insert into beer (id, name, manf, recyclable)
    values ('#{beer.id}','#{beer.name.db_norm}', '#{beer.manf}', '#{beer.recyclable ? 1 : 0}');"
  client.query(query)
end

def insert_bar(client, bar)
  query = "insert into bar (id, name, address)
    values ('#{bar.id}','#{bar.name.db_norm}', '#{bar.address.to_s}');"
  client.query(query)
end

def insert_beer_sale(client, bar, beer, price)
  query = "insert into sells (bar_id, beer_id, price)
    values ('#{bar.id}', '#{beer.id}', '#{price}');"
  client.query(query)
end

def insert_purchases(client, purchases)
  query = "insert into buys (bar_id, drinker_id, beer_id, quantity, day, bar_number, week_number)
    values"
  query << purchases.map { |buy|
      "('#{buy.bar_id}', '#{buy.person_id}', '#{buy.beer_id}', '#{buy.quantity}', '#{buy.day}', '#{buy.bar_number+1}', '#{buy.week_number}')"
    }.join(",") + ";"
  client.query(query)
end
