module FakeSNS
  class Action

    attr_reader :db, :params

    def self.param(fields, &block)
      fields.each do |field, key|
        define_method field do
          params.fetch(key, &block)
        end
      end
    end

    def initialize(db, params)
      @db = db
      @params = params
    end

    def call
      # override me, if needed
    end

    def account_id
      ENV['AWS_ACCOUNT_ID'] || SecureRandom.hex
    end

    def region
      ENV['AWS_REGION'] || 'us-east-1'
    end
  end
end
