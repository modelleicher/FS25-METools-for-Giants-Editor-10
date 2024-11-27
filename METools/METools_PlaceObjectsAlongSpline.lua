-- Author:Admin
-- Name:METools | Place Objects Along Spline
-- Namespace: local
-- Description: places objects along a spline in Z axis direction 
-- Icon:
-- Hide: no
-- AlwaysLoaded: no


-- set the adjustable Variables and Functions 
---------------------------------------------
local distanceBetweenObjects = 1
local function setObjectDistance(distance)
    distanceBetweenObjects = distance
end
local distanceBetweenObjectsRandomMax = distanceBetweenObjects
local function setDistanceBetweenObjectsRandomMax(distance)
    distanceBetweenObjectsRandomMax = distance
end


local sideOffset = 0
local function setSideOffset(offset)
    sideOffset = offset
end
local sideOffsetRandomMax = sideOffset
local function setSideOffsetRandomMax(offset)
    sideOffsetRandomMax = offset
end


local yOffset = 0
local function setYOffset(offset)
    yOffset = offset
end
local yOffsetRandomMax = 0
local function setYOffsetRandomMax(offset)
    yOffsetRandomMax = offset
end


local adjustToTerrain = false
local function setAdjustToTerrain(value)
    adjustToTerrain = value
end

local randomizeObjects = false
local function setRandomizeObjects(value)
    randomizeObjects = value
end

local randomYRotation = false
local function setRandomYRotation(value)
    randomYRotation = value
end


-- the actual function that does all the work
---------------------------------------------
function placeObjectsAlongSpline( )

	local script = {}


    if (getNumSelected() == 0) then
        print("Error: Select a Spline and an Object.")
        return nil
    end
	
	if adjustToTerrain then
		script.terrainId = getChild(getRootNode(), "terrain")
	end


	script.spline = getSelection(0)
    script.object = getSelection(1)

	local splineLength = getSplineLength(script.spline) 
		
	
    script.splinePoint = distanceBetweenObjects / splineLength
    script.splinePointRandomMax = distanceBetweenObjectsRandomMax / splineLength
    
    if randomizeObjects then
        script.numberOfChildren = getNumOfChildren(script.object)
    end
    
    local splinePosition = 0.0
    while splinePosition <= 1.0 do
        -- get XYZ at position on spline
        local splinePositionX, splinePositionY, splinePositionZ = getSplinePosition(script.spline, splinePosition)

        -- directional vector at the point
        local splineDirectionX, splineDirectionY, splineDirectionZ   = getSplineDirection (script.spline, splinePosition)
        script.vecDx, script.vecDy, script.vecDz = EditorUtils.crossProduct(splineDirectionX, splineDirectionY, splineDirectionZ, 0, 1, 0)
        
        if not randomizeObjects then
            script.newObject = clone(script.object, true)
        else 
            local randomNumber = math.random(0, script.numberOfChildren -1)
            script.newObject = clone(getChildAt(script.object, randomNumber), true)
        end

        -- random side offset 
        local sideOffsetValue = math.random(sideOffset*100000, sideOffsetRandomMax*100000) * 0.00001
        
        -- random Y offset
        local yOffsetValue = math.random(yOffset*100000, yOffsetRandomMax*100000) * 0.00001

		-- calculating offsets, sideOffsets need to have vector influence
        local mPosX_offset = splinePositionX + sideOffsetValue * script.vecDx
        local mPosZ_offset = splinePositionZ + sideOffsetValue * script.vecDz        
        local mPosY_offset = splinePositionY + yOffsetValue 
        
        if adjustToTerrain then
            mPosY_offset = getTerrainHeightAtWorldPos(script.terrainId, splinePositionX, splinePositionY, splinePositionZ)
        end

		-- finally setting translation and direction of the object
        setTranslation(script.newObject, mPosX_offset, mPosY_offset, mPosZ_offset)

        local dirX, dirY, dirZ = getSplineDirection(script.spline, splinePosition)
        setDirection(script.newObject, dirX, 0, dirZ, 0, 1, 0)
        
        -- random Y Rotation
        if randomYRotation then 
            local x,y,z = getRotation(script.newObject)
            setRotation(script.newObject, x, math.rad(math.random(0, 360)), z)
        end
       
        -- random spline moving distance 
		local splinePointAddValue = math.random(script.splinePoint*100000, script.splinePointRandomMax*100000) * 0.00001
		
        --splinePosition = splinePosition + splinePointAdd
        splinePosition = splinePosition + splinePointAddValue
    end
end
source("editorUtils.lua");





-- UI
-- create basic frame
local labelWidthFrame = 120.0

local frameSizer = UIRowLayoutSizer.new()
local myFrame = UIWindow.new(frameSizer, "METools | Place Objects along Spline")

local borderSizer = UIRowLayoutSizer.new()
UIPanel.new(frameSizer, borderSizer)

local rowSizer = UIRowLayoutSizer.new()
UIPanel.new(borderSizer, rowSizer, -1, -1, -1, -1, BorderDirection.ALL, 10, 1)

------------------------------------------------------------------------
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
------------------------------------------------------------------------
------------------------------------------------------------------------


-- Actual UI
------------------------------------------------------------------------
meToolsUtils_addSlider("Object Distance Min:", 1, 0, 100, setObjectDistance, "float", labelWidthFrame, 3)
meToolsUtils_addSlider("Object Distance Max:", 1, 0, 100, setDistanceBetweenObjectsRandomMax, "float", labelWidthFrame, 17)


meToolsUtils_addSlider("Side Offset Min:", 1, 0, 100, setSideOffset, "float", labelWidthFrame, 3)
meToolsUtils_addSlider("Side Offset Max:", 1, 0, 100, setSideOffsetRandomMax, "float", labelWidthFrame, 17)


meToolsUtils_addSlider("Y Offset Min:", 1, 0, 100, setYOffset, "float", labelWidthFrame, 3)
meToolsUtils_addSlider("Y Offset Max:", 1, 0, 100, setYOffsetRandomMax, "float", labelWidthFrame, 17)

meToolsUtils_addCheckBox("Adjust to Terrain Height      ", "", setAdjustToTerrain, labelWidthFrame, 15)
meToolsUtils_addCheckBox("Random Y Rotation      ", "", setRandomYRotation, labelWidthFrame, 15)
meToolsUtils_addCheckBox("Randomize Objects             ", "", setRandomizeObjects, labelWidthFrame, 25)


UIButton.new(rowSizer, "Place Objects", placeObjectsAlongSpline)



meToolsUtils_addLabel("", nil, labelWidthFrame, 30)
meToolsUtils_addLabel("Script Explanation:", nil, labelWidthFrame, 6)
meToolsUtils_addLabel("This Script allows you to Place objects along a spline.", nil, labelWidthFrame, 3)
meToolsUtils_addLabel("You need to select a Spline and then an Object first.", nil, labelWidthFrame, 14)

meToolsUtils_addLabel("Each Input with Min & Max can be used to randomize between min and max.", nil, labelWidthFrame, 3)
meToolsUtils_addLabel("If no randomizing is intended use the same Value for both.", nil, labelWidthFrame, 14)

meToolsUtils_addLabel("Object Distance -> Distance between the Objects along the Spline.", nil, labelWidthFrame, 3)
meToolsUtils_addLabel("Side Offset  -> The Offset of the Objects sideways to the Spline. Negative Values work.", nil, labelWidthFrame, 3)
meToolsUtils_addLabel("Y Offset  -> The Y Offset of the Objects to the Spline, Negative Values work.", nil, labelWidthFrame, 3)
meToolsUtils_addLabel("Adjust to Terrain Height -> If this is ticked the objects are placed on the Terrain.", nil, labelWidthFrame, 3)
meToolsUtils_addLabel("Random Y Rotation -> Adds a random rotation to Y Axis", nil, labelWidthFrame, 3)
meToolsUtils_addLabel("Randomize Objects -> Randomizes between Objects to Place along the Spline", nil, labelWidthFrame, 3)
meToolsUtils_addLabel("                     For this to work create a Transformgroup filled with the", nil, labelWidthFrame, 3)
meToolsUtils_addLabel("                     Objects to randomize from and select the Transformgroup ", nil, labelWidthFrame, 3)
meToolsUtils_addLabel("                     instead of the Object ", nil, labelWidthFrame, 30)

myFrame:showWindow()

