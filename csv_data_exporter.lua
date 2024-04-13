--csv_data_exporter
--- Developed using LifeBoatAPI - Stormworks Lua plugin for VSCode - https://code.visualstudio.com/download (search "Stormworks Lua with LifeboatAPI" extension)
--- If you have any issues, please report them here: https://github.com/nameouschangey/STORMWORKS_VSCodeExtension/issues - by Nameous Changey


--[====[ HOTKEYS ]====]
-- Press F6 to simulate this file
-- Press F7 to build the project, copy the output from /_build/out/ into the game to use
-- Remember to set your Author name etc. in the settings: CTRL+COMMA


--[====[ EDITABLE SIMULATOR CONFIG - *automatically removed from the F7 build output ]====]
---@section __LB_SIMULATOR_ONLY__
do
    ---@type Simulator -- Set properties and screen sizes here - will run once when the script is loaded
    simulator = simulator
    simulator:setScreen(1, "2x2")

    simulator:setProperty("Record Nums Up to Ch:", 5)
    simulator:setProperty("Record Bools Up to Ch:", 5)
    simulator:setProperty("Sample every n-th tick:", 1)
    simulator:setProperty("Convert bools to 1-0:", true)
    simulator:setProperty("Debug screen:", true)

        simulator:setProperty("Num 1 Label", "Laser")
        simulator:setProperty("Num 2 Label", "")
        simulator:setProperty("Num 3 Label", "")
        simulator:setProperty("Num 4 Label", "")
        simulator:setProperty("Num 5 Label", "")
        simulator:setProperty("Num 6 Label", "")
        simulator:setProperty("Num 7 Label", "")
        simulator:setProperty("Num 8 Label", "")
        simulator:setProperty("Num 9 Label", "")
        simulator:setProperty("Num 10 Label", "")
        simulator:setProperty("Num 11 Label", "")
        simulator:setProperty("Num 12 Label", "")
        simulator:setProperty("Num 13 Label", "")
        simulator:setProperty("Num 14 Label", "")
        simulator:setProperty("Num 15 Label", "")
        simulator:setProperty("Num 16 Label", "")
        simulator:setProperty("Num 17 Label", "")
        simulator:setProperty("Num 18 Label", "")
        simulator:setProperty("Num 19 Label", "")
        simulator:setProperty("Num 20 Label", "")
        simulator:setProperty("Num 21 Label", "")
        simulator:setProperty("Num 22 Label", "")
        simulator:setProperty("Num 23 Label", "")
        simulator:setProperty("Num 24 Label", "")
        simulator:setProperty("Num 25 Label", "")
        simulator:setProperty("Num 26 Label", "")
        simulator:setProperty("Num 27 Label", "")
        simulator:setProperty("Num 28 Label", "")
        simulator:setProperty("Num 29 Label", "")
        simulator:setProperty("Num 30 Label", "")
        simulator:setProperty("Num 31 Label", "")
        simulator:setProperty("Num 32 Label", "")

        simulator:setProperty("Bool 1 Label", "")
        simulator:setProperty("Bool 2 Label", "")
        simulator:setProperty("Bool 3 Label", "")
        simulator:setProperty("Bool 4 Label", "")
        simulator:setProperty("Bool 5 Label", "")
        simulator:setProperty("Bool 6 Label", "")
        simulator:setProperty("Bool 7 Label", "")
        simulator:setProperty("Bool 8 Label", "")
        simulator:setProperty("Bool 9 Label", "")
        simulator:setProperty("Bool 10 Label", "")
        simulator:setProperty("Bool 11 Label", "")
        simulator:setProperty("Bool 12 Label", "")
        simulator:setProperty("Bool 13 Label", "")
        simulator:setProperty("Bool 14 Label", "")
        simulator:setProperty("Bool 15 Label", "")
        simulator:setProperty("Bool 16 Label", "")
        simulator:setProperty("Bool 17 Label", "")
        simulator:setProperty("Bool 18 Label", "")
        simulator:setProperty("Bool 19 Label", "")
        simulator:setProperty("Bool 20 Label", "")
        simulator:setProperty("Bool 21 Label", "")
        simulator:setProperty("Bool 22 Label", "")
        simulator:setProperty("Bool 23 Label", "")
        simulator:setProperty("Bool 24 Label", "")
        simulator:setProperty("Bool 25 Label", "")
        simulator:setProperty("Bool 26 Label", "")
        simulator:setProperty("Bool 27 Label", "")
        simulator:setProperty("Bool 28 Label", "")
        simulator:setProperty("Bool 29 Label", "")
        simulator:setProperty("Bool 30 Label", "")
        simulator:setProperty("Bool 31 Label", "")
        simulator:setProperty("Bool 32 Label", "")

    -- Runs every tick just before onTick; allows you to simulate the inputs changing
    ---@param simulator Simulator Use simulator:<function>() to set inputs etc.
    ---@param ticks     number Number of ticks since simulator started
    function onLBSimulatorTick(simulator, ticks)

        simulator:setInputNumber(1, simulator:getSlider(1)*50)
        simulator:setInputNumber(2, 0)

        -- NEW! button/slider options from the UI
        simulator:setInputBool(31, simulator:getIsToggled(1))       -- if button 1 is clicked, provide an ON pulse for input.getBool(31)

        simulator:setInputBool(32, simulator:getIsToggled(2))       -- make button 2 a toggle, for input.getBool(32)
    end;
end
---@endsection


--[====[ IN-GAME CODE ]====]

-- try require("Folder.Filename") to include code from another file in this, so you can store code in libraries
-- the "LifeBoatAPI" is included by default in /_build/libs/ - you can use require("LifeBoatAPI") to get this, and use all the LifeBoatAPI.<functions>!
--csv_data_exporter
ticks = 0
receipts = 0
sends = 0
waiting = false
exportStatus = "Not exported"
currentPairIndex = 1
currentBatchStartIndex = 1
batchSize = 180
currentDataType = "nums"
exportTimer = 0
exportRate = 3
drawTick = 0
length = 0
progress = 0

data = {nums = {}, bools = {}}
channelNames = {nums = {}, bools = {}}

numNums = property.getNumber("Record Nums Up to Ch:") --confusing name i know
numBools = property.getNumber("Record Bools Up to Ch:")
sampleRate = property.getNumber("Sample every n-th tick:")
convertBools = property.getBool("Convert bools to 1-0:")
debugScreen = property.getBool("Debug screen:")
autoRefresh = property.getBool("Clear CSV on spawn:")

for i = 1, numNums do
    if property.getText("Num "..i.." Label:") == '' then
        channelNames.nums[i] = 'Empty'
    else
        channelNames.nums[i] = property.getText("Num "..i.." Label:")
    end
end
for i = 1, numBools do
    if property.getText("Bool "..i.." Label:") == '' then
        channelNames.bools[i] = 'Empty'
    else
        channelNames.bools[i] = property.getText("Bool "..i.." Label:")
    end
end

if autoRefresh then
    async.httpGet(1575, "/refresh")
end

function onTick()
    start = input.getBool(30)
    export = input.getBool(31)
    refresh = input.getBool(32) and not down
    down = input.getBool(32)

    if start and not export then --we are RECORDING data!
        ticks = ticks + 1
        if ticks % sampleRate == 0 then -- time to record data
            data.nums[#data.nums+1] = {}
            data.bools[#data.bools+1] = {}

            for i = 1, numNums do --record nums that arent empty
                if channelNames.nums[i] ~= "Empty" then
                    data.nums[#data.nums][i] = string.format("%.4f", input.getNumber(i))
                end
            end

            for i = 1, numBools do --record bools
                if channelNames.bools[i] ~= "Empty" then
                    if convertBools then
                        if input.getBool(i) then
                            data.bools[#data.bools][i] = 1
                        else
                            data.bools[#data.bools][i] = 0
                        end
                    else
                        data.bools[#data.bools][i] = tostring(input.getBool(i))
                    end
                end
            end

            ticks = 0
        else --if its not a sample tick, then just duplicate the data
            data.nums[#data.nums+1] = data.nums[#data.nums]
            data.bools[#data.bools+1] = data.bools[#data.bools]
        end
    end

    -- Check for export and start exporting data
    if export and exportStatus ~= "Exported!" then
        exportTimer = exportTimer + 1
        if not waiting then
            exportStatus = "Exporting"
            sendBatch(currentDataType) --y'all this is a seriously scary function i have no clue if it works
            waiting = true
        else
            exportStatus = "Waiting"
            ticks = ticks + 1
            if ticks >= exportRate then
                waiting = false
                ticks = 0
            end
        end
    end

    if refresh then
        async.httpGet(1575, "/refresh")
    end

    output.setNumber(1, exportTimer/60)
    output.setBool(1, exportStatus == "Exported!")
end

function httpReply(port, request_body, response_body)
    if request_body:find('packet') then
        if response_body == "Values recorded" then
            exportStatus = "Exporting"
            receipts = receipts + 1
        else
            exportStatus = "Failed"
            ticks = 0
        end
    elseif request_body:find('refresh') then
        if response_body ~= "Refreshed" then
            exportStatus = "Refresh failed"
        end
    end
end

function extractColumn(data, column) --used for grabbing channel pairs
    local extractedColumn = {}
    for i, row in ipairs(data) do
        table.insert(extractedColumn, row[column])
    end
    return extractedColumn
end

function sendBatch(type) --used to send data in batches of 180 (3 seconds of data)
    if type == "nums" then --this is stupid
        local valuesToSend = {}
        local pair = extractColumn(data.nums, currentPairIndex)

        --gather values we're sending
        for i = currentBatchStartIndex, math.min(#pair, currentBatchStartIndex + batchSize - 1) do
            table.insert(valuesToSend, pair[i])
        end

        currentBatchStartIndex = currentBatchStartIndex + batchSize

        local sendString = tableToCSV(valuesToSend)
        if sendString == '' then
            if #extractColumn(data.nums, currentPairIndex + 1) > 0 then
                currentPairIndex = currentPairIndex + 1
                currentBatchStartIndex = 1
            else
                currentDataType = "bools"
                currentBatchStartIndex = 1
                currentPairIndex = 1
                sendBatch("bools")
            end
        else
            async.httpGet(1575, "/packet?name="..channelNames.nums[currentPairIndex].."&values="..sendString)
            sends = sends + 1
        end

        if currentBatchStartIndex > #pair+batchSize then
            if #extractColumn(data.nums, currentPairIndex + 1) > 0 then
                currentPairIndex = currentPairIndex + 1
                currentBatchStartIndex = 1
            else
                currentDataType = "bools"
                currentBatchStartIndex = 1
                currentPairIndex = 1
                sendBatch("bools")
            end
        end
    else --im sorry, little one
        local valuesToSend = {}
        local pair = extractColumn(data.bools, currentPairIndex)
    
        for i = currentBatchStartIndex, math.min(#pair, currentBatchStartIndex + batchSize - 1) do --minus 1 from 180 for some reason
            table.insert(valuesToSend, pair[i])
        end
    
        currentBatchStartIndex = currentBatchStartIndex + batchSize
    
        local sendString = tableToCSV(valuesToSend)
        if sendString == '' then
            if #extractColumn(data.bools, currentPairIndex + 1) > 0 then
                currentPairIndex = currentPairIndex + 1
                currentBatchStartIndex = 1
            else
                exportStatus = "Exported!"
            end
        else
            async.httpGet(1575, "/packet?name="..channelNames.bools[currentPairIndex].."&values="..sendString)
            sends = sends + 1
        end
    
        if currentBatchStartIndex > #pair+batchSize then
            if #extractColumn(data.bools, currentPairIndex + 1) > 0 then
                currentPairIndex = currentPairIndex + 1
                currentBatchStartIndex = 1
            else
                exportStatus = "Exported!"
            end
        end
    end
end

-- Function to convert table to CSV string
function tableToCSV(tbl)
    local csvStr = ""
    for i = 1, #tbl do
        csvStr = csvStr..tbl[i] ..','
    end
    return csvStr:sub(1,#csvStr-1)
end

function recursiveLength(tbl)
    local count = 0
    for _, value in pairs(tbl) do
        if type(value) == "table" then
            count = count + recursiveLength(value)
        else
            count = count + 1
        end
    end
    return count
end


function onDraw()
    drawTick = drawTick + 1
    if drawTick % 60 == 0 then
        drawTick = 0
        length = recursiveLength(data)
        par = #extractColumn(data.nums, currentPairIndex)
        if export and receipts > 0 then
            estProgress = length/par/batchSize*par*0.84
            progress = math.floor((receipts/estProgress)*100)
        end
    end
    if debugScreen then
        screen.drawText(1,1,exportStatus)
        screen.drawText(1,7,"#tbl:"..length)
        screen.drawText(1,14,"receipts:"..receipts)
        screen.drawText(1,21,"sends:"..sends)
        screen.drawText(1,27,"ticks:"..ticks)
        screen.drawText(1,34,"pair:"..currentPairIndex)
        screen.drawText(1,41,"bch:"..currentBatchStartIndex.."-"..currentBatchStartIndex+batchSize)
        screen.drawText(1,49,"#par:"..#extractColumn(data.nums, currentPairIndex))
        screen.drawText(1,56,"type:"..currentDataType)
    else
        screen.drawText(1,1,exportStatus)
        screen.drawText(1,7,"Pts:"..length)
        screen.drawText(1,14,string.format("ETA:%.1fs", length/((180*(60/exportRate))/1.4)))
        screen.drawText(1,21,string.format("Timer:%.1fs", exportTimer/60))
        screen.drawText(1,27,string.format("%%Done:%.1f%%", progress))
    end
end
