class Captcha
  PTQUESTION = "What is this card's power?"
  DAMAGEQUESTION = "How much damage does this card deal?"
  CAPTCHAS = [
    #["Fugitive Wizard", PTQUESTION, 1  ],
    ["Merfolk of the Pearl Trident", PTQUESTION, 1],
    #["Wandering Ones", PTQUESTION, 1   ],
    ["Runeclaw Bear", PTQUESTION, 2    ],
    #["Cylian Elf", PTQUESTION, 2       ],
    #["Glory Seeker", PTQUESTION, 2     ],
    #["Walking Corpse", PTQUESTION, 2   ],
    #["Centaur Courser", PTQUESTION, 3  ],
    ["Canyon Minotaur", PTQUESTION, 3  ],
    #["Rhox Brute", PTQUESTION, 4       ],
    ["Rumbling Baloth", PTQUESTION, 4  ],
    ["Hollowhenge Beast", PTQUESTION, 5],
    ["Kindercatch", PTQUESTION, 6      ],
    
    ["Shock", DAMAGEQUESTION, 2],
    ["Lightning Bolt", DAMAGEQUESTION, 3],
    #["Searing Spear", DAMAGEQUESTION, 3],
    ["Lightning Blast", DAMAGEQUESTION, 4],
    ["Lava Axe", DAMAGEQUESTION, 5],
    ["Searing Wind", DAMAGEQUESTION, 10],
  ]
  
  def self.get_question
    # Returns an array of [cardname, question, answer]
    CAPTCHAS.sample
  end
  def self.check_answer(params)
    captcha_card = params[:captcha_card]
    captcha_answer = params[:captcha_answer]
    captcha = CAPTCHAS.select{ |captcha| captcha[0] == captcha_card }[0]
    if captcha_answer && captcha_answer.to_i == captcha[2]
      true
    else
      false
    end
  end
end
