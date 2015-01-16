require 'octokit'

module Capistrano
  module Github
    class API
      class Deployment
        attr_accessor :created_at, :ref, :sha, :creator_login, :payload, :statuses, :id, :environment

        class Status
          attr_accessor :created_at, :state
        end
      end

      REPO_FORMAT = /git@github.com:([\S]*)\/([\S]*).git/

      attr_reader :client

      def initialize(repo_url, token)
        @client = Octokit::Client.new(access_token: token)
        @repo = parse_repo_url(repo_url)
      end

      def create_deployment(branch, options = {})
        @client.create_deployment(@repo, branch, options)
      end

      def create_deployment_status(id, state)
        @client.create_deployment_status(deployment_url(id), state)
      end

      def deployments(options = {})
        @client.deployments(@repo, options).map do |d|
          Deployment.new.tap do |dep|
            dep.created_at = d.created_at
            dep.sha = d.sha
            dep.ref = d.ref
            dep.creator_login = d.creator.login
            dep.payload = d.payload
            dep.id = d.id
            dep.environment = d.environment

            dep.statuses = deployment_statuses(d.id)
          end
        end
      end

      private

      def deployment_statuses(id)
        @client.deployment_statuses(deployment_url(id))
      end

      def deployment_url(id)
        "repos/#{@repo}/deployments/#{id}"
      end

      def parse_repo_url(url)
        repo_match = url.match(REPO_FORMAT)
        "#{repo_match[1]}/#{repo_match[2]}"
      end
    end
  end
end
