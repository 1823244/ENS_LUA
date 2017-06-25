ma =
{
    -- Exponential Moving Average (EMA)
    -- EMA[i] = (EMA[i]-1*(per-1)+2*X[i]) / (per+1)
    -- Параметры:
    -- period - Период скользящей средней
    -- get - функция с одним параметром (номер в выборке), возвращающая значение выборки
    -- Возвращает массив, при обращению к которому будет рассчитываться только необходимый элемент
    -- При повторном обращении будет возвращено уже рассчитанное значение
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
--Попробуем, как оно работает. В качестве источника данных берем массив значений, период усреднения пусть будет равен 3.
local data={1,3,5,7,9,2,4,6,8,0}
local s = ma.ema(3, function(i) return data[i] end)
-- Вводим сразу 7 элемент без обращения к предыдущим
message("7".." ------------------- " .. tostring(s[7]))

-- А теперь все значения
for i=1,#data do
message(tostring(i).." ------------------- " .. tostring(s[i]))
end

end
