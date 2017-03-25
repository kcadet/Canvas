#
# Copyright (C) 2012 Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#

class CrocodocSessionsController < ApplicationController
  before_filter :require_user
  include HmacHelper

  def show
    blob = extract_blob(params[:hmac], params[:blob],
                        "user_id" => @current_user.global_id,
                        "type" => "crocodoc")
    attachment = Attachment.find(blob["attachment_id"])

    if attachment.crocodoc_available?
      annotations = params[:annotations] ?
        value_to_boolean(params[:annotations]) :
        true

      crocodoc = attachment.crocodoc_document
      url = crocodoc.session_url(:user => @current_user,
                                 :annotations => annotations,
                                 :crocodoc_ids => blob["crocodoc_ids"])

      # For the purposes of reporting student viewership, we only
      # care if the original attachment owner is looking
      attachment.touch(:viewed_at) if attachment.context == @current_user

      redirect_to url
    else
      render :text => "Not found", :status => :not_found
    end

  rescue HmacHelper::Error
    render :text => 'unauthorized', :status => :unauthorized
  rescue Timeout::Error
    render :text => "Service is currently unavailable. Try again later.",
           :status => :service_unavailable
  end
end