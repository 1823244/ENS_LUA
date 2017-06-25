
--ִכÿ גסוץ סךמכüחÿשטץ סנוהםטץ סמחהא¸ל ןנמסענאםסעגמ טלום  ס טלוםול ma. ֿמלושאול ג םודמ ןונגף‏ פףםךצט‏, גûקטסכÿ‏שף‏ ‎ךסןמםוםצטאכüםף‏ סךמכüחÿשף‏ סנוהם‏‏.
ma={ema=function(period,get) 
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



function main()
--ֿמןנמבףול, ךאך מםמ נאבמעאוע. ֲ ךאקוסעגו טסעמקםטךא האםםûץ בונול לאססטג חםאקוםטי, ןונטמה ףסנוהםוםטÿ ןףסעü בףהוע נאגום 3.
local data={1,3,5,7,9,2,4,6,8,0}
local s = ma.ema(3, function(i) return data[i] end)
-- ֲגמהטל סנאחף 7 ‎כולוםע בוח מבנאשוםטÿ ך ןנוהûהףשטל
message("7".." ------------------- " .. tostring(s[7]))

-- ְ עוןונü גסו חםאקוםטÿ
for i=1,#data do
message(tostring(i).." ------------------- " .. tostring(s[i]))
end

end
