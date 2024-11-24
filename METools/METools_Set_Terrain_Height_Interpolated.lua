-- Author:Admin
-- Name:METools | Set Terrain Height Interpolated
-- Description: This Script sets the Terrain Height along a spline with smooth/interpolated edges to the untouched terrain.
-- Icon:
-- Hide: no
-- AlwaysLoaded: no

-- Changelog:
-- Conversion to GE10/FS25 - added UI


-- HOW TO USE (Deprecated please use UI instead)
-- 1. Set the custom values you want
-- :: lengthResolution = the resolution in meters along the length of the spline
-- :: widthResolution = the resolution in meters side-side 
-- -- (with 2m Terrain Resolution you should use at least 1 or lower to not have sharp edges in between)
-- -- (also there is no downside to a smaller resolution aside from longer run-time for the script so.. best to keep at 0.5 or below)
-- :: sideWidthTotal = the total width of the adjusted part including the smoothing parts (from middle to one side - absolute width is x2)
-- :: sideWidthInner = width of the inner part where no smoothing is performed (from middle to one side - absolute width is x2)
-- :: heightOffset = you can offset the height of the inner part here 
-- 2. select the spline you want to work with (or splines) and run the script

-- ADJUST VALUES HERE:
local lengthResolution = 0.1
local widthResolution = 0.1
local sideWidthTotal = 15
local sideWidthInner = 6
local heightOffset = 0.0


-- NO ADJUSTMENT BELOW HERE
---------------------------


function setLengthResolution(value)
    lengthResolution = value
end
function setWidthResolution(value)
    widthResolution = value
end
function setSideWidthTotal(value)
    sideWidthTotal = value
end
function setSideWidthInner(value)
    sideWidthInner = value
end
function setHeightOffset(value)
    heightOffset = value
end


local savedTerrainLevels = {}


function getSplineRelevantValues()
    
    -- get root
    local sceneId = getRootNode()
    local terrainId = 0
    
    -- find terrain
    for i = 0, getNumOfChildren(sceneId) - 1 do
        local id = getChildAt(sceneId, i) 
        if (getName(id) == "terrain") then
            terrainId = id
            break
        end
    end
    if terrainId == 0 then
        print("Error: Terrain node not found")
        return nil
    end
        
    -- get selected splines
    if getNumSelected() == 0 then
        print("Error: Select at least one spline.")
        return nil
    end
    
    local splineIds = {}
    for i = 0, getNumSelected() - 1 do
        local spline = getSelection(i)
        table.insert(splineIds, spline)
    end

    return terrainId, splineIds
end


function setTerrainHeight( )
    
	-- load the splines 
    local terrainId, splineIds = getSplineRelevantValues()

    if splineIds ~= nil then
    
        -- cycle selected splines
        for splineIndex , splineId in pairs(splineIds) do

            
            -- calculate piece point for current spline 
            local splineLength = getSplineLength(splineId)
            local splinePiecePoint = lengthResolution / splineLength 
            
            -- saving the current heights 
            startingTerrainHeightLeft = {}
            startingTerrainHeightRight = {}
            
            -- walk along the spline to save the outer most terrain height 
            local splinePos = 0.0
            while splinePos <= 1.0 do	
            
                -- get global position
                local posX, posY, posZ = getSplinePosition(splineId, splinePos)
                local height = posY + heightOffset
                local dirX, dirY, dirZ   = worldDirectionToLocal(splineId, getSplineDirection(splineId, splinePos))
                local vecDx, vecDy, vecDz = EditorUtils.crossProduct(dirX, dirY, dirZ, 0, 1, 0)
                
                local newPosXLeft = posX + sideWidthTotal * vecDx
                local newPosYLeft = posY + sideWidthTotal * vecDy
                local newPosZLeft = posZ + sideWidthTotal * vecDz
                local newPosXRight = posX  - sideWidthTotal * vecDx
                local newPosYRight = posY  - sideWidthTotal * vecDy
                local newPosZRight = posZ  - sideWidthTotal * vecDz

                local heightCurrentLeft = getTerrainHeightAtWorldPos(terrainId, newPosXLeft, newPosYLeft, newPosZLeft)
                local heightCurrentRight = getTerrainHeightAtWorldPos(terrainId, newPosXRight, newPosYRight, newPosZRight)	 

                startingTerrainHeightLeft[splinePos] = heightCurrentLeft
                startingTerrainHeightRight[splinePos] = heightCurrentRight

                splinePos = splinePos + splinePiecePoint
            end
            
            -- walk along the spline to set the terrain heights 
            local splinePos = 0.0
            while splinePos <= 1.0 do
            
                -- get global position
                local posX, posY, posZ = getSplinePosition(splineId, splinePos)
                local height = posY + heightOffset
                local dirX, dirY, dirZ   = worldDirectionToLocal(splineId, getSplineDirection(splineId, splinePos))
                local vecDx, vecDy, vecDz = EditorUtils.crossProduct(dirX, dirY, dirZ, 0, 1, 0)	
                
                -- set terrain height at center				
                setTerrainHeightAtWorldPos(terrainId, posX, posY, posZ, height) 
                        
                -- set terrain height from center to inner radius (sideWidthInner)
                for i = widthResolution, sideWidthInner, widthResolution do
                    local newPosXLeft = posX + i * vecDx
                    local newPosYLeft = posY + i * vecDy
                    local newPosZLeft = posZ + i * vecDz
                    local newPosXRight = posX  - i * vecDx
                    local newPosYRight = posY  - i * vecDy
                    local newPosZRight = posZ  - i * vecDz

                    setTerrainHeightAtWorldPos(terrainId, newPosXLeft, newPosYLeft, newPosZLeft, height)
                    setTerrainHeightAtWorldPos(terrainId, newPosXRight, newPosYRight, newPosZRight, height)               
                end			

                -- interpolated part - set terrain height from inner radius to outer radius 
                for x = sideWidthInner, sideWidthTotal, widthResolution do
                
                    local newPosXLeft = posX + x * vecDx
                    local newPosYLeft = posY + x * vecDy
                    local newPosZLeft = posZ + x * vecDz
                    local newPosXRight = posX  - x * vecDx
                    local newPosYRight = posY  - x * vecDy
                    local newPosZRight = posZ  - x * vecDz			
                    
                    -- range of outer radius part 
                    local range = sideWidthTotal - sideWidthInner
                    
                    -- current position in that range 
                    local currentPosition = x - sideWidthInner
                    
                    -- normalized 
                    local normalized = currentPosition / range
                    
                    
                    
                    local differenceLeft = height - startingTerrainHeightLeft[splinePos]
                    local differenceRight = height - startingTerrainHeightRight[splinePos]
                    
                    local newHeightLeft = height - differenceLeft * normalized
                    local newHeightRight = height - differenceRight * normalized

                    
                    setTerrainHeightAtWorldPos(terrainId, newPosXLeft, newPosYLeft, newPosZLeft, newHeightLeft)
                    setTerrainHeightAtWorldPos(terrainId, newPosXRight, newPosYRight, newPosZRight, newHeightRight)      				
                end

            
                splinePos = splinePos + splinePiecePoint
            end	
        
        end
    end
end
source("editorUtils.lua");



-- UI
-- create basic frame
local labelWidthFrame = 120.0

local frameSizer = UIRowLayoutSizer.new()
local myFrame = UIWindow.new(frameSizer, "METools | Set Terrain Height Interpolated")

local borderSizer = UIRowLayoutSizer.new()
UIPanel.new(frameSizer, borderSizer)

local rowSizer = UIRowLayoutSizer.new()
UIPanel.new(borderSizer, rowSizer, -1, -1, -1, -1, BorderDirection.ALL, 10, 1)


-- helper functions used in all my Scripts for the different UI Elements
function meToolsUtils_addTextArea(name, startValue, callback, lableWidth, spacing)
    local sizer = UIColumnLayoutSizer.new()
    UIPanel.new(rowSizer, sizer, -1, -1, -1, -1, BorderDirection.BOTTOM, spacing)
    UILabel.new(sizer, name, TextAlignment.LEFT, -1, -1, lableWidth);
    local textArea = UITextArea.new(sizer, startValue, 1);
    textArea:setOnChangeCallback(callback)
end

function meToolsUtils_addCheckBox(name, text, callback, lableWidth, spacing)
    local sizer = UIColumnLayoutSizer.new()
    UIPanel.new(rowSizer, sizer, -1, -1, -1, -1, BorderDirection.BOTTOM, spacing)
    UILabel.new(sizer, name, TextAlignment.LEFT, -1, -1, lableWidth);
    local checkBox = UICheckBox.new(sizer, text, startValue);
    checkBox:setOnChangeCallback(callback)
end

function meToolsUtils_addSlider(name, startValue, minValue, maxValue, callback, sliderType, lableWidth, spacing)
    local sizer = UIColumnLayoutSizer.new()
    UIPanel.new(rowSizer, sizer, -1, -1, -1, -1, BorderDirection.BOTTOM, spacing)
    UILabel.new(sizer, name, false, TextAlignment.LEFT,VerticalAlignment.TOP, -1, -1, lableWidth);

    if sliderType == "slider" then
        local slider = UISlider.new(sizer, startValue, minValue, maxValue);
        slider:setOnChangeCallback(callback)
    elseif sliderType == "int" then
        local slider = UIIntSlider.new(sizer, startValue, minValue, maxValue);
        slider:setOnChangeCallback(callback)
    elseif sliderType == "float" then
        local sliderF = UIFloatSlider.new(sizer, startValue, minValue, maxValue);
        sliderF:setOnChangeCallback(callback)
    end    
end

function meToolsUtils_addLabel(name, width, lableWidth, spacing)
    local width = width
    if width == nil then
        width = lableWidth
    end
    local sizer = UIColumnLayoutSizer.new()
    UIPanel.new(rowSizer, sizer, -1, -1, -1, -1, BorderDirection.BOTTOM, spacing)
    UILabel.new(sizer, name, TextAlignment.LEFT, -1, -1, width);
end

-- Actual UI
meToolsUtils_addSlider("Length Resolution:", 1, 0, 100, setLengthResolution, "float", labelWidthFrame, 3)
meToolsUtils_addSlider("Width Resolution:", 1, 0, 100, setWidthResolution, "float", labelWidthFrame, 3)
meToolsUtils_addSlider("Side Width Total:", 6, 0, 100, setSideWidthTotal, "float", labelWidthFrame, 3)
meToolsUtils_addSlider("Side With Inner:", 2, 0, 100, setSideWidthInner, "float", labelWidthFrame, 3)
meToolsUtils_addSlider("Height Offset:", 0, 0, 100, setHeightOffset, "float", labelWidthFrame, 30)

UIButton.new(rowSizer, "Set Terrain Height", setTerrainHeight)

meToolsUtils_addLabel("", nil, labelWidthFrame, 30)
meToolsUtils_addLabel("Script Explanation:", nil, labelWidthFrame, 6)
meToolsUtils_addLabel("This Script allows you to transform Terrain to a Spline.", nil, labelWidthFrame, 3)
meToolsUtils_addLabel("Compared to the Default Script this allows you to have the edges", nil, labelWidthFrame, 3)
meToolsUtils_addLabel("Interpolated/smoothed with the existing terrain.", nil, labelWidthFrame, 14)
meToolsUtils_addLabel("Length Resolution -> The lengthwise resolution of the Terrain Editing.", nil, labelWidthFrame, 3)
meToolsUtils_addLabel("Width Resolution  -> The widthwise resolution of the Terrain Editing", nil, labelWidthFrame, 3)
meToolsUtils_addLabel("Side Width Total  -> Total width of edited Area. Radius Value. Actual Width *2", nil, labelWidthFrame, 3)
meToolsUtils_addLabel("Side Width Inner  -> Inner width of edited Area. The area kept 'flat'. Also *2", nil, labelWidthFrame, 3)
meToolsUtils_addLabel("Height Offset     -> Offset in Height to the Spline. Optional, default 0", nil, labelWidthFrame, 30)




myFrame:showWindow()

