require 'sinatra'
require 'json'
require 'yaml'
require 'active_support/all'

module OASDB
  class GeneratedAPIHelper
    attr_reader :last_id, :ds

    OAS_RUBY_DATA_VALIDATION = {
      'string' => ->(data) { raise ArgumentError if String(data).length == 0 },
      'integer' => ->(data) { Integer(data) }
    }.freeze

    def initialize
      @last_id = 0
      @ds = {}
    end

    def next_id
      @last_id += 1
    end

    def sanitize_payload(payload, schema)
      sanitized_payload = payload.deep_dup

      payload.each do |name, value|
        sanitized_payload.delete(name) unless schema[name].present?
      end

      sanitized_payload
    end

    def validate_field(name, value, schema)
      OAS_RUBY_DATA_VALIDATION[schema.dig(name, 'type')].call(value)
      true
    rescue ArgumentError
      false
    end

    def valid_obj?(payload, schema, mode = :create)
      if mode == :create
        return false if payload.keys.length != schema.keys.length # Check for missing fields.
      else # :update
        return false if payload.keys.length == 0
      end

      validation_results = {}

      payload.each do |name, value|
        validation_results[name] = validate_field(name, value, schema)
      end

      validation_results.values.all?
    end

    def create_obj(payload)
      id = next_id
      obj = payload.merge({ 'id' => id })
      ds[id] = obj
      [true, obj]
    end

    def read_obj(key)
      obj = ds[key]
      [!obj.nil?, obj]
    end

    def update_obj(key, payload)
      obj = ds[key]
      return false if obj.nil?

      ds[key] = ds[key].merge(payload)
      true
    end

    def delete_obj(key)
      obj = ds.delete(key)
      !obj.nil?
    end
  end
end

api_helper = OASDB::GeneratedAPIHelper.new

post '/incidents' do
  request.body.rewind
  schema = {"title"=>{"description"=>"A title to identify the incident.", "type"=>"string"}, "service_id"=>{"description"=>"The ID of the affected service.", "type"=>"integer"}, "assignee_id"=>{"description"=>"The ID of the colaborator assigned to deal with the issue.", "type"=>"integer"}}
  payload = JSON.parse(request.body.read)
  sanitized_payload = api_helper.sanitize_payload(payload, schema)
  halt 422 unless api_helper.valid_obj?(sanitized_payload, schema)

  result, obj = api_helper.create_obj(sanitized_payload)

  res_body = JSON.dump(obj.slice('id'))
  res_header = { 'Content-Type' => 'application/json' }

  [201, res_header, res_body]
end

get '/incidents/:incident_id' do
  request.body.rewind

  obj_id = Integer(params['incident_id'])
  found, obj = api_helper.read_obj(obj_id)

  halt 404 unless found

  res_body = JSON.dump(obj)
  res_header = { 'Content-Type' => 'application/json' }

  [200, res_header, res_body]
rescue ArgumentError
  halt 404
end

put '/incidents/:incident_id' do
  request.body.rewind
  schema = {"title"=>{"description"=>"A title to identify the incident.", "type"=>"string"}, "service_id"=>{"description"=>"The ID of the affected service.", "type"=>"integer"}, "assignee_id"=>{"description"=>"The ID of the colaborator assigned to deal with the issue.", "type"=>"integer"}}
  payload = JSON.parse(request.body.read)
  sanitized_payload = api_helper.sanitize_payload(payload, schema)
  halt 422 unless api_helper.valid_obj?(sanitized_payload, schema, :update)

  obj_id = Integer(params['incident_id'])
  updated = api_helper.update_obj(obj_id, sanitized_payload)

  halt 404 unless updated

  200
rescue ArgumentError
  halt 404
end

delete '/incidents/:incident_id' do
  request.body.rewind

  obj_id = Integer(params['incident_id'])
  deleted = api_helper.delete_obj(obj_id)

  halt 404 unless deleted

  200
rescue ArgumentError
  halt 404
end
