local textstream = {}

function textstream:new()
    local stream = {
        columns = {},
        rows = {},
        columnMargin = 4
    }

    function stream:newRow()
        stream.rows[#stream.rows+1] = {
            data = {}
        }
    end

    function stream:getMaxColumnCount()
        local highestColumn = 0
        for _,__ in pairs(stream.rows) do
            for k,v in pairs(__.data) do
                if v.cIndex > highestColumn then
                    highestColumn = v.cIndex
                end
            end
        end
        return highestColumn
    end

    function stream:columnExists(index, columnIndex)
        local rows = stream.rows

        local row = rows[index]
        if not row then
            rows[index] = {
                data = {}
            }
            row = rows[index]
        end
        local data = row.data

        for k,v in pairs(data) do
            if v.cIndex == columnIndex then return true end
        end
        return false
    end

    function stream:addToRow(index, columnIndex, text)
        local columns = stream.columns
        local rows = stream.rows
        local column = columns[columnIndex]

        local row = rows[index]
        if not row then
            rows[index] = {
                data = {}
            }
            row = rows[index]
        end
        local data = row.data

        if not column then
            columns[columnIndex] = {
                largestLength = #text,
                columnMargin = stream.columnMargin
            }
        else
            if column.largestLength < #text then
                column.largestLength = #text
            end
        end

        if not stream:columnExists(index, columnIndex) then
            data[#data+1] = {value = text, cIndex = columnIndex}
        end
    end

    function stream:changeColumn(row, columnIndex, text)
        local columns = stream.columns
        local rows = stream.rows
        local column = columns[columnIndex]

        if rows[row] == nil then
            stream:addToRow(row, columnIndex, '')
        end

        local row = rows[row]
        for _,data in pairs(row.data) do
            if data.cIndex == columnIndex then
                data.value = text
                if column.largestLength < #text then
                    column.largestLength = #text
                end
            end
        end
    end

    function stream:getColumnText(index, columnIndex)
        local rows = stream.rows

        local row = rows[index]
        if not row then
            rows[index] = {
                data = {}
            }
            row = rows[index]
        end

        for _,data in pairs(row.data) do
            if data.cIndex == columnIndex then
                return data.value
            end
        end
        return ''
    end


    function stream:setColumnMargin(column, margin)
        if stream.columns[column] then
            stream.columns[column].columnMargin = margin
        end
    end

    function stream:toString()
        local text = ""

        for x = 1, #stream.rows do
            for y = 1, stream:getMaxColumnCount() do
                local data = nil
                if stream.rows[x] ~= nil then
                    for k,v in pairs(stream.rows[x].data) do
                        if v.cIndex == y then
                            data = v
                        end
                    end
                end

                local column = stream.columns[y]
                if data then
                    text = text .. data.value
                    if #data.value < column.largestLength then
                        local extraSpaces = column.largestLength - #data.value
                        for i = 1, extraSpaces do
                            text = text .. ' '
                        end
                    end
                    for i = 1, column.columnMargin do
                        text = text .. ' '
                    end
                else
                    for i = 1, column.largestLength do
                        text = text .. ' '
                    end
                    for i = 1, column.columnMargin do
                        text = text .. ' '
                    end
                end
            end
            text = text .. '\n'
        end

        return text
    end

    return stream
end

return textstream
