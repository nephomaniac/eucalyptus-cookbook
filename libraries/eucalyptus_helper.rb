#
# Cookbook Name:: eucalyptus
# Library:: helper
#
# Author:: Matt Bacchi <mbacchi@hpe.com>
#
# © Copyright 2016 Hewlett Packard Enterprise Development Company LP
##
##Licensed under the Apache License, Version 2.0 (the "License");
##you may not use this file except in compliance with the License.
##You may obtain a copy of the License at
##
##    http://www.apache.org/licenses/LICENSE-2.0
##
##    Unless required by applicable law or agreed to in writing, software
##    distributed under the License is distributed on an "AS IS" BASIS,
##    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
##    See the License for the specific language governing permissions and
##    limitations under the License.
##

require 'chef/mixin/shell_out'

module EucalyptusHelper
   extend Chef::Mixin::ShellOut

   # get service state
   def self.getservicestate?(name, state)
      as_admin = "export AWS_DEFAULT_REGION=localhost; eval `clcadmin-assume-system-credentials` && "
      euserv_cmd = "#{as_admin} euserv-describe-services --expert --filter service-type=#{name}"
      cmd = shell_out(euserv_cmd)
      # change this to debug when tested well
      Chef::Log.info("`#{euserv_cmd}` returned: \n \"#{cmd.stdout.strip}\"")
      cmd.stdout.each_line.select do |l|
          if l.strip.include? "#{state}"
            Chef::Log.info("euserv-describe-services --expert --filter service-type=#{name} indicates the state is: \"#{state}\".")
            return true
          end
      end
      return false
   end

end