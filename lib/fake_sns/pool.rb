require 'celluloid/current'
require 'oj'

module FakeSNS
  class Pool
    class << self
      def deliver(delivery:)
        pool.async.deliver(delivery: delivery)
      end

      def pool
        @pool ||= Delivery.pool(size: 20)
      end
    end
  end

  class Delivery
    include Celluloid

    def deliver(delivery:)
      log "Delivering to #{delivery.arn}"
      resp = connection(delivery.endpoint) do |f|
        f.body = {
          "Type"             => "Notification",
          "MessageId"        => delivery.message.id,
          "TopicArn"         => delivery.message.topic_arn,
          "Subject"          => delivery.message.subject,
          "Message"          => Oj.dump({
            "default" => delivery.message.message_for_protocol(delivery.protocol)
          }),
          "Timestamp"        => delivery.message.received_at.strftime("%Y-%m-%dT%H:%M:%SZ"),
          "SignatureVersion" => "1",
          "Signature"        => "Fake",
          "SigningCertURL"   => "https://sns.us-east-1.amazonaws.com/SimpleNotificationService-f3ecfb7224c7233fe7bb5f59f96de52f.pem",
          "UnsubscribeURL"   => "", # TODO url to unsubscribe URL on this server
        }.to_json
        f.headers.merge!({
          "x-amz-sns-message-type"     => "Notification",
          "x-amz-sns-message-id"       => delivery.message.id,
          "x-amz-sns-topic-arn"        => delivery.message.topic_arn,
          "x-amz-sns-subscription-arn" => delivery.arn,
          "content-type"               => "text/plain; charset=utf-8",
          "user-agent"                 => "Amazon Simple Notification Service Agent"
        })
      end
      if resp.status.to_s != "200"
        log "Delivery failed with status #{resp.status}"
      else
        log "Delivery succeeded"
      end
    end

    private

    def log(message)
      puts "[DELIVERY][#{self.object_id}] #{message}"
    end

    def connection(endpoint, &block)
      u = URI(endpoint)
      hoststring = "#{u.scheme}://#{u.host}"
      if (u.scheme == 'http' && u.port != 80) ||
         (u.scheme == 'https' && u.port != 443)
        hoststring = "#{hoststring}:#{u.port}"
      end
      conn = Faraday.new(hoststring) do |c|
        c.use Faraday::Response::Logger
        c.use Faraday::Adapter::NetHttp
      end
      conn.basic_auth(u.user, u.password) if u.user && u.password
      conn.post(u.path, &block)
    end
  end
end
