lltechapter = {
    title = "LLTE: Персонажи",
    articles = {
        {
            title = "Кавалеры",
            picture = "data/textures/ui/encyclopedia/exploring/characters/cavaliers2.jpg",
            text = "После поражения Семьи и Коммуны, \\c(0d0)Кавалеры\\c() смогли усилить давление на Пиратов и Ксотан до разрушительного уровня. Пиратские аванпосты по всей галактике исчезают без следа, а мощные флоты кораблей Кавалеров уничтожают пиратские и ксотанские атаки на посты фракций. Это лишь вопрос времени, когда равновесие нарушится...",
            isUnlocked = function()
                if Player():getValue("encyclopedia_llte_cav5_done") then
                    return true
                else
                    return false
                end
            end
        },
        {
            title = "Враждебность",
            picture = "data/textures/ui/encyclopedia/exploring/characters/animosity.jpg",
            text = "После сокрушительной атаки \\c(0d0)Кавалеров\\c(), уничтожившей крупный пиратский аванпост и убившей тысячи, пираты были подавлены чувством потери и горя. Как они могут сражаться против такой мощи? Их горе быстро превратилось в ярость, и ответ казался очевидным — то, что они всегда делали лучше всего: пиратство.\nГоворили, что это невозможно, но они сделали это несмотря ни на что. Корабли были успешно захвачены у военной корпорации S.W.O.R.D. Это стало остриём копья в их борьбе за месть. Пираты назвали его в честь своей ненависти.\n\"Враждебность\" — это модернизированный \\c(0d0)разрушитель класса \"Клевер\"\\c(). Он крупнее обычного \"Клевера\" и использует броню и компоненты из триния вместо стандартных титана и нанонита. Также он оснащён \\c(0d0)опасной осадной пушкой\\c(), предназначенной для уничтожения крупных капитальных кораблей.",
            isUnlocked = function()
                if Player():getValue("encyclopedia_llte_animosity_found") then
                    return true
                else
                    return false
                end
            end
        },
        {
            title = "Артефакт Ксотан",
            picture = "data/textures/ui/encyclopedia/exploring/characters/artifact1.jpg",
            text = "Во время своего путешествия через барьер, \\c(0d0)Кавалеры\\c() нашли загадочный \\c(0d0)артефакт Ксотан\\c(). Неизвестно, как он оказался встроенным в разрушенный корабль Ксотан в отдалённом секторе. Исследования продолжаются, чтобы выяснить назначение артефакта.",
            isUnlocked = function()
                if Player():getValue("encyclopedia_llte_xsotan_artifact_found") then
                    return true
                else
                    return false
                end
            end
        },
        {
            title = "Артефакт Ксотан (продолжение)",
            picture = "data/textures/ui/encyclopedia/exploring/characters/artifact2.jpg",
            text = "Дальнейшие исследования артефакта показали, что он действует как \\c(0d0)маяк для привлечения кораблей Ксотан\\c() в сектор. Исследования продолжаются, чтобы найти подходящий способ использовать это против Ксотан.",
            isUnlocked = function()
                if Player():getValue("encyclopedia_llte_xsotan_artifact_contd_found") then
                    return true
                else
                    return false
                end
            end
        }
    }
}

table.insert(category.chapters, lltechapter)
