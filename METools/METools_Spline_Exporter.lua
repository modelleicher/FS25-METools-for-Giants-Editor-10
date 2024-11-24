-- Author:modelleicher
-- Name:METools | Spline Exporter
-- Description: Exporting a Spline directly to OBJ
-- Icon:
-- Hide: no
-- AlwaysLoaded: no

-- Changelog:
-- Conversion to GE10/FS25 - added UI

-- HOW TO USE
-- change the "splineResolution" below to the resolution you want (or leave at 1)
-- select the Spine to export
-- run the script, select the File in the File-Dialog which opens, have fun with the exportet spline :)


local splineResolution = 1.0 
function setSplineResolution(resolution)
    splineResolution = resolution 
end

local function exportSplineToOBJ()
    -- create and load obj file
    local objFilePath = openFileDialog("Select File", "*.obj")

    local objFileId = createFile(objFilePath, FileAccess.WRITE)
    
    if objFileId ~= nil and objFileId ~= 0 then
        -- create comment header line (not needed) 
        fileWrite(objFileId, "# Spline Export Giants Editor \n")


        -- get spline and values
        local splineId = getSelection(0)

        local splineLength = getSplineLength(splineId) 
        local splinePiecePoint = splineResolution / splineLength  -- relative size [0..1]

        -- store vertexPoints to connect lines with vertices later
        local vertexPoints = 0

        -- go along spline on given distances and write vertice-points to file
        local splinePos = 0.0
            while splinePos <= 1.0 do

            local posX, posY, posZ = getSplinePosition(splineId, splinePos)

            fileWrite(objFileId, "v "..tostring(posX).." "..tostring(posY).." "..tostring(posZ).."\n")    
            
            vertexPoints = vertexPoints + 1
            -- goto next point
            splinePos = splinePos + splinePiecePoint
        end

        -- write the line connections
        for i = 1, vertexPoints-1 do
            fileWrite(objFileId, "l "..tostring(i).." "..tostring(i+1).."\n")
        end
        delete(objFileId)
        print("File "..tostring(objFilePath).." Exported!")
    else
        print("File not exported. Please select Filename!")
    end
end



-- UI
-- create basic frame
local labelWidthFrame = 120.0

local frameSizer = UIRowLayoutSizer.new()
local myFrame = UIWindow.new(frameSizer, "METools | Export Spline to OBJ")

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

meToolsUtils_addSlider("Spline Resolution:", 1, 0, 100, setSplineResolution, "float", labelWidthFrame, 3)
meToolsUtils_addLabel("The resolution which the Spline is exported with. Default 1.", nil, labelWidthFrame, 3)
meToolsUtils_addLabel("1 Vertex Point per Spline Vertex.", nil, labelWidthFrame, 30)

UIButton.new(rowSizer, "Export", exportSplineToOBJ)

myFrame:showWindow()

