# Матрица взаимодействий

Профили в `content/items/profiles.json`; каждый вариант мебели задаёт только размеры/цвета (и при желании свои anchors). Код действий не зависит от `item_id`.

| Профиль | Девочка | Кошка | Собака | Варианты |
|---|---|---|---|---|
| bed | sit, sleep (sit → lie_prep → sleep, выход через stretch; у bed_heart — sleep_front лицом к игроку под одеялом-картинкой), repair (только bed_heart, когда изношена) | rest (прыжок, +износ) | rest (прыжок, +износ) | bed_rose, bed_star, bed_cloud, bed_heart |
| sofa | sit, read | rest | rest | sofa_mint, sofa_peach |
| seat | sit, read | rest | — | armchair_lilac, armchair_flower |
| desk | study (тетрадь), draw; стул отодвигается | — | — | desk_wood, desk_white |
| dining | eat | — | — | table_small, table_round_pink |
| wardrobe | dress (двери открываются → гардероб) | — | — | wardrobe_white, wardrobe_castle |
| mirror | admire, dress | — | — | mirror_oval, mirror_flower |
| window (фикс.) | look | watch | — | window_main |
| pet_bed | — | sleep | sleep | petbed_round, petbed_heart |
| pet_house | — | sleep внутри (max_size) | только если помещается | cathouse_wood (≤1), cathouse_castle (≤2) |
| scratcher | — | scratch | — | scratcher_post, scratcher_tower |
| tunnel | — | run_through | run_through (≤1) | tunnel_rainbow |
| bowl_food / bowl_water | fill, fill_treat | eat / drink (если наполнено) | eat / drink | по 2 варианта |
| bath | wash (нужен питомец) | купание | купание | bathtub_small |
| groom | brush (нужен питомец) | расчёсывание | расчёсывание | groom_kit |
| teaser | play_cat | pounce | — | teaser_rod |
| device / wall_device | toggle (свет, ТВ, радио, часы) | — | — | lamp_floor, lamp_mushroom, tv_retro, radio_cute, clock_wall |

Правила: резервирование слотов (`InteractionService`), одно место у актёра одновременно, эксклюзивная блокировка питомца (перенос, уход, совместная игра), совместное действие запрещено если питомец в закрытом домике/на руках/занят, эвикция при перемещении/уборке мебели.
