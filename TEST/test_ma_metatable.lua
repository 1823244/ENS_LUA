ma =
{
    -- Exponential Moving Average (EMA)
    -- EMA[i] = (EMA[i]-1*(per-1)+2*X[i]) / (per+1)
    -- ���������:
    -- period - ������ ���������� �������
    -- get - ������� � ����� ���������� (����� � �������), ������������ �������� �������
    -- ���������� ������, ��� ��������� � �������� ����� �������������� ������ ����������� �������
    -- ��� ��������� ��������� ����� ���������� ��� ������������ ��������
    ema =
        function(period,get) 
            return setmetatable( 
                        {},
                        { __index = function(tbl,indx)
                                              if indx == 1 then
                                                  tbl[indx] = get(1)
                                              else
                                                  tbl[indx] = (tbl[indx-1] * (period-1) + 2 * get(indx)) / (period + 1)
                                              end
                                              return tbl[indx]
                                            end
                        })
       end
}





function main()
--���������, ��� ��� ��������. � �������� ��������� ������ ����� ������ ��������, ������ ���������� ����� ����� ����� 3.
local data={1,3,5,7,9,2,4,6,8,0}
local s = ma.ema(3, function(i) return data[i] end)
-- ������ ����� 7 ������� ��� ��������� � ����������
message("7".." ------------------- " .. tostring(s[7]))

-- � ������ ��� ��������
for i=1,#data do
message(tostring(i).." ------------------- " .. tostring(s[i]))
end

end
