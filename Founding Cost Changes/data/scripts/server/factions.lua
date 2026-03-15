
--Нормализем стартовые ресурсы, что бы не быть с голой жопой в начале игры на сложности выше нормальной.
local FCC = initializePlayer
function initializePlayer(player)
    FCC(player)
	server = Server()
	local settings = GameSettings()
	if settings.playTutorial then 
	else
		if server.difficulty <= Difficulty.Normal then player:receive(0, -2500)
		else
			player:receive(5000, 1000)
		end
	end
end
