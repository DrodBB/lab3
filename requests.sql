-- ==============================================================================
-- Лабораторная работа №3: Межтабличные связи
-- Вариант 32
--
-- Постановка задачи варианта 32:
-- Вывести на экран информацию обо всех сцепках и их составах при условии, что:
--   1) если определен состав для незарегистрированной сцепки, оставить пустое поле;
--   2) если в сцепку не добавлено трамваев, оставить пустое поле.
-- ==============================================================================


-- ==============================================================================
-- ЭТАП 1. Проверка обеспечения ссылочной целостности данных
-- ==============================================================================
-- В исходном состоянии в базе данных действует внешний ключ fk_sostavscepok_scepki.
-- Выполняем симметричное соединение (INNER JOIN): выводятся только те строки,
-- для которых есть взаимное соответствие в обеих таблицах (сцепки с 1 по 7).
SELECT 
    c.number_scepki,
    c.kol_vagonov,
    c.dlina_scepki,
    c.data_sostavleniya,
    c.vozmozhnost_reversivnogo_dvizheniya,
    s.tramvai_number,
    s.number_scepki AS sostav_scepki,
    s.main_tramvai,
    s.vagon_number_in_scepka
FROM public.scepki c
INNER JOIN public.sostavscepok s ON c.number_scepki = s.number_scepki
ORDER BY c.number_scepki, s.vagon_number_in_scepka;


-- ==============================================================================
-- ЭТАП 2. Нарушение ссылочной целостности данных
-- ==============================================================================
-- Для внесения некорректных данных временно удаляем ограничение внешнего ключа:
ALTER TABLE public.sostavscepok DROP CONSTRAINT IF EXISTS fk_sostavscepok_scepki;

-- Добавляем в подчиненную таблицу составов записи с номером сцепки 99,
-- которой заведомо нет в главной таблице scepki:
INSERT INTO public.sostavscepok (tramvai_number, number_scepki, main_tramvai, vagon_number_in_scepka) VALUES
(991, 99, true, 1),
(992, 99, false, 2);


-- ==============================================================================
-- ЭТАП 3. Выполнение запроса по Условию 1 Варианта 32
-- ==============================================================================
-- Задание: «если определен состав для незарегистрированной сцепки, оставить пустое поле»
-- Реализация: правостороннее соединение (RIGHT JOIN).
-- Сохраняются все записи таблицы составов sostavscepok.
-- Для добавленных вагонов 991 и 992 (привязаны к несуществующей сцепке 99)
-- поля таблицы scepki заполняются значениями NULL ([null] в выводе).
SELECT 
    c.number_scepki,
    c.kol_vagonov,
    c.dlina_scepki,
    c.data_sostavleniya,
    c.vozmozhnost_reversivnogo_dvizheniya,
    s.tramvai_number,
    s.number_scepki AS sostav_scepki,
    s.main_tramvai,
    s.vagon_number_in_scepka
FROM public.scepki c
RIGHT JOIN public.sostavscepok s ON c.number_scepki = s.number_scepki
ORDER BY c.number_scepki ASC NULLS FIRST, s.tramvai_number;


-- ==============================================================================
-- ЭТАП 4. Выполнение запроса по Условию 2 Варианта 32
-- ==============================================================================
-- Задание: «если в сцепку не добавлено трамваев, оставить пустое поле»
-- Реализация: левостороннее соединение (LEFT JOIN).
-- Сохраняются все записи таблицы сцепок scepki.
-- Для сцепок 8, 9 и 10, в которые не включено ни одного вагона,
-- поля таблицы sostavscepok заполняются значениями NULL ([null] в выводе).
SELECT 
    c.number_scepki,
    c.kol_vagonov,
    c.dlina_scepki,
    c.data_sostavleniya,
    c.vozmozhnost_reversivnogo_dvizheniya,
    s.tramvai_number,
    s.number_scepki AS sostav_scepki,
    s.main_tramvai,
    s.vagon_number_in_scepka
FROM public.scepki c
LEFT JOIN public.sostavscepok s ON c.number_scepki = s.number_scepki
ORDER BY c.number_scepki, s.vagon_number_in_scepka;


-- ==============================================================================
-- ЭТАП 5. Выявление нарушения ссылочной целостности данных
-- ==============================================================================
-- Запрос находит в зависимой таблице составов те записи, для которых отсутствует
-- соответствующая запись в главной таблице сцепок (по условию c.number_scepki IS NULL):
SELECT 
    s.tramvai_number,
    s.number_scepki AS invalid_number_scepki,
    s.main_tramvai,
    s.vagon_number_in_scepka
FROM public.sostavscepok s
LEFT JOIN public.scepki c ON s.number_scepki = c.number_scepki
WHERE c.number_scepki IS NULL;


-- ==============================================================================
-- ЭТАП 6. Восстановление ссылочной целостности данных
-- ==============================================================================
-- ВНИМАНИЕ: Блок восстановления закомментирован, чтобы в базе данных сохранялись
-- тестовые записи для проверки работы преподавателем (выполнение этапов 3, 4 и 5).
-- Раскомментируйте и выполните данные команды, когда потребуется вернуть БД в исходный вид:

-- 1. Удаление некорректных записей, нарушающих целостность:
-- DELETE FROM public.sostavscepok
-- WHERE number_scepki NOT IN (SELECT number_scepki FROM public.scepki);

-- 2. Повторное создание внешнего ключа:
-- ALTER TABLE public.sostavscepok
-- ADD CONSTRAINT fk_sostavscepok_scepki FOREIGN KEY (number_scepki)
--     REFERENCES public.scepki (number_scepki)
--     ON UPDATE CASCADE
--     ON DELETE CASCADE;

-- 3. Контрольная проверка (запрос должен вернуть 0 строк):
-- SELECT s.tramvai_number, s.number_scepki
-- FROM public.sostavscepok s
-- LEFT JOIN public.scepki c ON s.number_scepki = c.number_scepki
-- WHERE c.number_scepki IS NULL;
