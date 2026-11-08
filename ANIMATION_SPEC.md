# Анимации

Скелеты векторные (`girl_painter.gd`, `pet_painter.gd`), позы — словари параметров, переход — смешивание за 0.2–0.8 с (`Actor.set_pose`).

## Девочка
Позы: stand, observe, sit, read, lie_prep, sleep, desk, desk_draw, eat, reach, admire, look_up, crouch, crouch_wash, crouch_brush, pet, carry, throw_wind, throw_release, tease, happy, stretch, fix_hair, surprised. Моргание, дыхание во сне, «z».
Ходьба: фаза = пройденная дистанция / (STRIDE/STANCE); ступня стоит на месте в фазе опоры (IK) → нет скольжения; шаг звучит в момент касания.
Состояния: Idle, Observe, Walk, Turn, Approach, SitTransition, Sitting, StandUp, SleepEnter, Sleeping, WakeUp, Eat, Study, Dress, Play, Pet, PickUpPet, CarryPet, PutDownPet, LookWindow, UseObject.
Каждое действие: вход (подход → поворот → смешивание позы + перемещение на anchor), цикл (время или до команды), выход (обратная последовательность), мягкое прерывание.

## Кошка/собака
Позы: stand, sit, lie, curl, eat, stretch, held, scratch, groom, crouch, pounce, bath, sniff, happy, play_bow. Походки: кошка — латеральная последовательность (BL, FL, BR, FR), собака/бег — диагональные пары. Прыжок на мебель — дуга вверх при attach/detach.

## Ограничения
Нет покадровых нарисованных клипов; специализированные позы заданы параметрически. Для финального арта предусмотрена замена рисовальщиков слоями без изменения логики.
