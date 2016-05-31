local bot, extension = require("lua-bot-api").configure('YOUR TOKEN HERE')

local function table_contains(table, element, query)
  if not query then
    query = 'value'
  end

  for k,v in pairs(table) do
    if query == 'value' and v == element then
        return true
    elseif query == 'key' and k == element then
        return true
    end
  end
  return false
end

local function tableElements(table,num)
    num=tonumber(num)
    local count=0
    for k,v in pairs(table) do
        count = count+1
    end
    
    if (count==num) then
        return true
    else
        return false
    end
end

local function checkSubscribers()
    local configs= load_data("./data/strangergroup.json")
    local index = 0
    
    if not configs then
        return false
    end
    
    for k,v in pairs(configs) do
        index=index+1
    end
    
    if index < 2 then
        return false
    else
        return true
    end
end

local function init_group(groupid)
    local configs= load_data("./data/strangergroup.json")
    group_id = tostring(groupid)
    
    if not configs[group_id] then
        configs[group_id] = {
            is_available = false,
            com_to = 0
        }
        
        save_data("./data/strangergroup.json",configs)
        return true
    end

    return false
end

local function get_is_available(groupid)
    local configs= load_data("./data/strangergroup.json")
    
    if not configs[tostring(groupid)] then
        return false
    end
    
    return configs[tostring(groupid)].is_available
end

local function get_com_id(groupid)
    local configs= load_data("./data/strangergroup.json")
    
    if not configs[tostring(groupid)] then
        return 0
    end
    
    if table_contains(configs,tostring(groupid),'key') then
        return configs[tostring(groupid)].com_to
    end
    
    return 0
end

local function search_for_groups(groupid)
    local configs= load_data("./data/strangergroup.json")
    local waiting = {}
    
    for k,v in pairs(configs) do
        if not (tonumber(k)==tonumber(groupid)) then
            if get_is_available(k) then
                local id=get_com_id(k)
                if tonumber(id) == 0 then
                    table.insert(waiting,k)
                end
            end
        end
    end

    if tableElements(waiting,0) then
        return 0
    end
    
    local rnd = waiting[math.random(#waiting)]
    
    if rnd then
        return rnd
    else
        return 0
    end
end

local function open_bridge(id1,id2)
    local configs= load_data("./data/strangergroup.json")
    
    if tonumber(id1)==tonumber(id2) then
        return false
    end
    
    if tonumber(id2)==0 then
        return false
    end
    
    configs[tostring(id1)].is_available = false
    configs[tostring(id1)].com_to = tonumber(id2)
    
    configs[tostring(id2)].is_available = false
    configs[tostring(id2)].com_to = tonumber(id1)
    save_data("./data/strangergroup.json",configs)
    return true
end

local function set_as_available(groupid)
    local configs= load_data("./data/strangergroup.json")
    
    configs[tostring(groupid)].is_available = true
    save_data("./data/strangergroup.json",configs)
end

local function reset_on_end(groupid)
    local configs= load_data("./data/strangergroup.json")
    
    local temp = tonumber(configs[tostring(groupid)].com_to)
    
    if temp==0 then
        configs[tostring(groupid)].is_available = false
        configs[tostring(groupid)].com_to = 0
        save_data("./data/strangergroup.json",configs)
        return 0
    else
        configs[tostring(groupid)].is_available = false
        configs[tostring(groupid)].com_to = 0
        configs[tostring(temp)].is_available = false
        configs[tostring(temp)].com_to = 0
    end
    
    save_data("./data/strangergroup.json",configs)
    return temp
end

local function control_if_chatting(groupid)
    local configs= load_data("./data/strangergroup.json")
    local is_av = configs[tostring(groupid)].is_available
    local cto = configs[tostring(groupid)].com_to
    
    if not is_av then
        if tonumber(cto)~=0 then
            return true
        else
            return false
        end
    else
        return false
    end
end

local function get_bot_about()
    local text = "This bot is developed by @Seg_fault from LM.\n"
    .."Based on lua-api wrapper from @cosmonawt.\n"
    .."Please feel free to report any bug or suggesting new functions in our group [to be created soon]\n"
    .."This bot does not collect any personal data! it just stores your group ID to let the bot forward anonymously msgs and media files\n\n"
    .."Have fun!"
    
    return text
end

local function get_bot_help()
    local text = "=== BOT GUIDE ===\n\n"
        .."/start: begin searching for a match\n"
        .."/end: close current chat\n"
        .."/[your text]: sends the message (don't use square brackets).\nEx: /hello world! :)"
        .."\n\nPlease notice that media (pics, stickers, videos and vocals) forwarding is ALWAYS ON, so if you are using this bot in a group and you started a chat, it will forward (anonymously, ofc) any media you send."
    return text
end
        



extension.onTextReceive = function(msg)
    
    local matches = {msg.text:match('^/(.+)$')}
    
    if not checkSubscribers() then
        local output = "Not enough groups!"
        bot.sendMessage(msg.chat.id,output)
        return
    end
    
    if(matches[1]=='start')then
        local void = init_group(msg.chat.id)
        
        if control_if_chatting(msg.chat.id) then
            local reply="Nope! First you must close your current chat."
            bot.sendMessage(msg.chat.id,reply)
            return
        end
        
        set_as_available(msg.chat.id)
        local output = "Searching for a group..."
        bot.sendMessage(msg.chat.id,output)
        local val = search_for_groups(msg.chat.id)
        
        if open_bridge(msg.chat.id,val) then
            output="Match found. Have fun! :)"
            bot.sendMessage(msg.chat.id,output)
            bot.sendMessage(val,output)
            return
        end
        return
    end
    
    if(matches[1]=='end')then
        local dest2 = reset_on_end(msg.chat.id)
        local output = ""
        
        if dest2 == 0 then
            output = "Ok, search stopped. \nUse /start to search again for a group!"
            bot.sendMessage(msg.chat.id,output)
        else
            output = "Your partner left the chat :( use /start to start a new conversation!"
            bot.sendMessage(dest2,output)
            local output2 = "Ok, chat closed :3"
            bot.sendMessage(msg.chat.id,output2)
        end
        
        return
    end
    
    if (matches[1]=='help') then
        local output = get_bot_help()
        bot.sendMessage(msg.chat.id,output)
    end
    
    if (matches[1]=='help@strangerGroupBot') then
        local output = get_bot_help()
        bot.sendMessage(msg.chat.id,output)
    end
    
    if (matches[1]=='about') then
        local output = get_bot_about()
        bot.sendMessage(msg.chat.id,output)
    end
    
    if (matches[1]=='about@strangerGroupBot') then
        local output = get_bot_about()
        bot.sendMessage(msg.chat.id,output)
    end
    
    if matches[1] then
        local text = matches[1]
        --print("your text is "..text)
        local dest = get_com_id(msg.chat.id)
        bot.sendMessage(dest,text)
    end
end


extension.onPhotoReceive = function(msg)
	print("Photo received!")
	if control_if_chatting(msg.chat.id) then
	    local dest = get_com_id(msg.chat.id)
	    bot.sendPhoto(dest,msg.photo[1].file_id)
	    return
    end
end


extension.onVideoReceive = function(msg)
	print("Video received!")
	if control_if_chatting(msg.chat.id) then
	    local dest = get_com_id(msg.chat.id)
	    bot.sendVideo(dest,msg.video.file_id)
	    return
    end
end


extension.onStickerReceive = function(msg)
	print("Sticker received!")
	if control_if_chatting(msg.chat.id) then
	    local dest = get_com_id(msg.chat.id)
	    bot.sendSticker(dest,msg.sticker.file_id)
	    return
    end
end


extension.onVoiceReceive = function(msg)
	print("Voice received!")
	if control_if_chatting(msg.chat.id) then
	    local dest = get_com_id(msg.chat.id)
	    bot.sendVoice(dest,msg.voice.file_id)
	    return
    end
end


extension.onAudioReceive = function(msg)
	print("Audio received!")
	if control_if_chatting(msg.chat.id) then
	    local dest = get_com_id(msg.chat.id)
	    bot.sendAudio(dest,msg.audio.file_id)
	    return
    end
end

extension.run()
