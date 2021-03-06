#
# Cookbook Name:: jenkins
# Provider:: job
#
# Author:: Doug MacEachern <dougm@vmware.com>
# Author:: Fletcher Nichol <fnichol@nichol.ca>
#
# Copyright:: 2010, VMware, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

def load_current_resource
  @current_resource = Chef::Resource::JenkinsJob.new(@new_resource.name)
  validate_job_config!
  @current_resource
end

def action_create
  if !exists? # job does not exist in jenkins
    post_job(new_job_url)
    Chef::Log.debug("#{@new_resource} does not exist - creating.")
    new_resource.updated_by_last_action(true)
  else # job exists attempt to update
    action_update
  end
end

def action_update
  if exists? # job exists
    post_job(job_url)
    Chef::Log.debug("#{@new_resource} exists - updating")
    new_resource.updated_by_last_action(true)
  else # job does not exist
    action_create
  end
end

def action_delete
  jenkins_cli "delete-job #{@new_resource.job_name}"
end

def action_disable
  jenkins_cli "disable-job #{@new_resource.job_name}"
end

def action_enable
  jenkins_cli "enable-job #{@new_resource.job_name}"
end

def action_build
  jenkins_cli "build #{@new_resource.job_name}"
end

private

def validate_job_config!
  unless ::File.exist?(@new_resource.config)
    raise "'#{@new_resource.config}' does not exist or is not a valid Jenkins config file!"
  end
end

def job_url
  "#{@new_resource.url}/job/#{@new_resource.job_name}/config.xml"
end

def new_job_url
  "#{@new_resource.url}/createItem?name=#{@new_resource.job_name}"
end

def exists?
  @exists ||= begin
    url = URI.parse(job_url)
    response = Chef::REST::RESTRequest.new(:GET, url, nil).call
    Chef::Log.debug("#{@new_resource} GET #{url.request_uri} == #{response.code}")
    response.kind_of?(Net::HTTPSuccess)
  end
end

def post_job(url)
  url = URI.parse(url)
  Chef::Log.debug("#{@new_resource} POST #{url.request_uri} using #{@new_resource.config}")
  body = IO.read(@new_resource.config)
  headers = {"Content-Type" => "text/xml"}
  response = Chef::REST::RESTRequest.new(:POST, url, body, headers).call
  response.error! unless response.kind_of?(Net::HTTPSuccess)
end
