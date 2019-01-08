filesName$ = "sections\" + selected$ ("TextGrid")

tiers = do ("Get number of tiers")

tierName$ = do$ ("Get tier name...", 1)
fileName$ = filesName$ + "-" + tierName$ + ".csv"
value$ = do$ ("Get label of interval...", 1, 1)
writeFile (fileName$, value$)

for i from 2 to tiers
    tierName$ = do$ ("Get tier name...", i)
    fileName$ = filesName$ + "-" + tierName$ + ".csv"
    writeFile (fileName$, "")
    intervals = do ("Get number of intervals...", i)
    for j to intervals
        label$ = do$ ("Get label of interval...", i, j)
        if label$ != ""
            start = do ("Get start point...", i, j)
            end = do ("Get end point...", i, j)
	    line$ = label$ + "," + string$(start) + "," + string$(end)
            appendFileLine (fileName$, line$)
        endif
    endfor
endfor
