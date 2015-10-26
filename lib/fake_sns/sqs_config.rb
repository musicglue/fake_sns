module FakeSNS
  class SqsConfig
    include Virtus.model

    attribute :sqs_endpoint, String
    attribute :sqs_port, Integer
    attribute :access_key_id, String
    attribute :access_key_id, String
    attribute :region, String
    attribute :use_ssl, Boolean
  end
end