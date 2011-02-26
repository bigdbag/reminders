class ApiController < ApplicationController
  def check
    
    # @reminders = Reminder.where("(appointment > ?) && (appointment < ?) && ( ISNULL(flag1) || ISNULL(flag2) || ISNULL(flag3))", Time.now.utc, Time.now.utc+1.week)

    @reminders = Reminder.where("(appointment > ?) && (appointment < ?) && ( flag1 IS NULL || flag2 IS NULL || flag3 IS NULL)", Time.now.utc, Time.now.utc+1.week)

    
    @reminders.each do |reminder| 
           
      if reminder.appointment-1.hour < Time.now.utc && reminder.flag3.nil?
        
        # Send SMS
        RestClient.get 'http://api.tropo.com/1.0/sessions', {:params => {
          :action => 'create', 
          :token => '848b6b17c6229844827847b381a4a7e25c72d0750ec751bc0d10072e58eaa12683b6ea0a8aa5e166ee7bfcc8', 
          :phonenumber => formatphone(reminder.phonenumber), 
          :remindermessage => reminder.message + ' at ' + reminder.appointment.to_s}}
        
        # Write Flag3
        @reminder = Reminder.find(reminder.id)
        @reminder.flag3 = true
        @reminder.save
        
      elsif reminder.appointment-1.day < Time.now.utc  && reminder.flag2.nil?
        
        # Place outbound reminder call
        RestClient.get 'http://api.tropo.com/1.0/sessions', {:params => {
          :action => 'create', 
          :token => '3d5eed33429706408efcc0e92307b044ba2ecb3c2e641f69f9179b54e9d04af908e583112195de9ec7b05b9e', 
          :phonenumber => formatphone(reminder.phonenumber), 
          :remindermessage => reminder.message + ' at ' + reminder.appointment.to_s}}
        
        # Write Flag2
        @reminder = Reminder.find(reminder.id)
        @reminder.flag2 = true
        @reminder.save
        
      elsif reminder.appointment-1.week < Time.now.utc && reminder.flag1.nil?
        
        # Place outbound reminder call
        RestClient.get 'http://api.tropo.com/1.0/sessions', {:params => {
          :action => 'create', 
          :token => '3d5eed33429706408efcc0e92307b044ba2ecb3c2e641f69f9179b54e9d04af908e583112195de9ec7b05b9e', 
          :phonenumber => formatphone(reminder.phonenumber), 
          :remindermessage => reminder.message + ' at ' + reminder.appointment.to_s}}
        
        # Write Flag1
        @reminder = Reminder.find(reminder.id)
        @reminder.flag1 = true
        @reminder.save
      end      
    end
    
    if @reminders
      render :text => "sent " + @reminders.length.to_s + " reminders"
    else
      render :text => "no reminders"
    end
  end
  
  def formatphone(phone)
    @phone = phone.gsub("(", "").gsub(")", "").gsub("-", "").gsub(".", "").gsub(" ", "")
    if @phone[0..0] != '1'
      @phone = '1' + @phone
    end
    return @phone
  end
end
