function BulletinBoard.checkRemoveBulletins(ostime, r)
	if #bulletins <= 0 then return end
	local servertime = Server().unpausedRuntime

	for i = #bulletins, 1, -1 do
		if bulletins[i].TimeAdded then -- check to see if it has a time added value...
			--local timeOnBoard = os.difftime(bulletins[i].TimeAdded, ostime)
			local timeOnBoard = servertime - bulletins[i].TimeAdded
			if (timeOnBoard >= 900 and timeOnBoard < 1800 and r:test(0.15)) or -- 15-30 mins, 15% chance of removal
				(timeOnBoard >= 1800 and timeOnBoard < 3600 and r:test(0.35)) or -- 30-60 mins, 35% chance of removal
				(timeOnBoard >= 3600 and timeOnBoard < 5400 and r:test(0.75)) or -- 60-90 mins, 75% chance of removal
				timeOnBoard >= 5400 then -- 90 mins and over, 100% chance of removal
				BulletinBoard.removeBulletin(i)
			end
		else -- ...if not, add one.
			bulletins[i].TimeAdded = ostime
		end
	end
end