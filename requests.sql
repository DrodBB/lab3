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
-- Проверяем наличие внешнего ключа fk_sostavscepok_scepki между таблицами sostavscepok и scepki
SELECT 
    tc.table_schema, 
    tc.constraint_name, 
    tc.table_name, 
    kcu.column_name, 
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name 
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
  AND tc.table_name = 'sostavscepok';

-- Симметричное соединение (INNER JOIN) при соблюдении ссылочной целостности:
-- Выводятся только те записи, для которых есть соответствие в обеих таблицах.
SELECT 
    c.number_scepki,
    c.kol_vagonov,
    c.dlina_scepki,
    c.data_sostavleniya,
    c.vozmozhnost_reversivnogo_dvizheniya,
    s.tramvai_number,
    s.main_tramvai,
    s.vagon_number_in_scepka
FROM public.scepki c
INNER JOIN public.sostavscepok s ON c.number_scepki = s.number_scepki
ORDER BY c.number_scepki, s.vagon_number_in_scepka;


-- ==============================================================================
-- ЭТАП 2. Нарушение ссылочной целостности данных
-- ==============================================================================
-- Для добавления записей, противоречащих внешнему ключу, временно удаляем ограничение:
ALTER TABLE public.sostavscepok DROP CONSTRAINT IF EXISTS fk_sostavscepok_scepki;

-- Добавляем в подчиненную таблицу составов записи с номером сцепки 99,
-- которой заведомо нет в главной таблице scepki:
INSERT INTO public.sostavscepok (tramvai_number, number_scepki, main_tramvai, vagon_number_in_scepka) VALUES
(991, 99, true, 1),
(992, 99, false, 2);


-- ==============================================================================
-- ЭТАП 3. Запрос с левосторонним соединением (LEFT JOIN)
-- ==============================================================================
-- Включает все сцепки из таблицы scepki.
-- Для сцепок 8, 9, 10 (в которые трамваи не добавлены) поля состава содержат NULL.
-- Выполняется условие 2 Варианта 32: «если в сцепку не добавлено трамваев, оставить пустое поле».
SELECT 
    c.number_scepki,
    c.kol_vagonov,
    c.dlina_scepki,
    c.data_sostavleniya,
    c.vozmozhnost_reversivnogo_dvizheniya,
    s.tramvai_number,
    s.number_scepki AS sostav_number_scepki,
    s.main_tramvai,
    s.vagon_number_in_scepka
FROM public.scepki c
LEFT JOIN public.sostavscepok s ON c.number_scepki = s.number_scepki
ORDER BY c.number_scepki, s.vagon_number_in_scepka;


-- ==============================================================================
-- ЭТАП 4. Запрос с правосторонним соединением (RIGHT JOIN)
-- ==============================================================================
-- Включает все составы из таблицы sostavscepok.
-- Для трамваев 991 и 992 (привязаны к несуществующей сцепке 99) поля таблицы scepki содержат NULL.
-- Выполняется условие 1 Варианта 32: «если определен состав для незарегистрированной сцепки, оставить пустое поле».
SELECT 
    c.number_scepki,
    c.kol_vagonov,
    c.dlina_scepki,
    c.data_sostavleniya,
    c.vozmozhnost_reversivnogo_dvizheniya,
    s.tramvai_number,
    s.number_scepki AS sostav_number_scepki,
    s.main_tramvai,
    s.vagon_number_in_scepka
FROM public.scepki c
RIGHT JOIN public.sostavscepok s ON c.number_scepki = s.number_scepki
ORDER BY s.number_scepki, s.vagon_number_in_scepka;


-- ==============================================================================
-- ЭТАП 5. Выявление нарушения ссылочной целостности данных
-- ==============================================================================
-- Запрос находит записи в таблице составов, для которых нет родительской записи в таблице сцепок:
SELECT 
    s.tramvai_number,
    s.number_scepki AS invalid_scepka_code,
    s.main_tramvai,
    s.vagon_number_in_scepka
FROM public.sostavscepok s
LEFT JOIN public.scepki c ON s.number_scepki = c.number_scepki
WHERE c.number_scepki IS NULL;


-- ==============================================================================
-- ЭТАП 6. ИТОГОВЫЙ ЗАПРОС ВАРИАНТА 32 (FULL OUTER JOIN)
-- ==============================================================================
-- Выводит информацию обо всех сцепках и их составах с одновременным выполнением обоих условий:
-- 1) Для незарегистрированной сцепки (трамваи 991, 992) поля сцепки остаются пустыми (NULL);
-- 2) Для сцепок без добавленных трамваев (сцепки 8, 9, 10) поля состава остаются пустыми (NULL).
SELECT 
    c.number_scepki AS scepki_number,
    c.kol_vagonov,
    c.dlina_scepki,
    c.data_sostavleniya,
    c.vozmozhnost_reversivnogo_dvizheniya,
    s.tramvai_number,
    s.number_scepki AS sostav_scepki_number,
    s.main_tramvai,
    s.vagon_number_in_scepka
FROM public.scepki c
FULL OUTER JOIN public.sostavscepok s ON c.number_scepki = s.number_scepki
ORDER BY COALESCE(c.number_scepki, s.number_scepki), s.vagon_number_in_scepka;


-- ==============================================================================
-- ЭТАП 7. Восстановление ссылочной целостности данных
-- ==============================================================================
-- 1. Удаление некорректных записей, нарушающих целостность данных:
DELETE FROM public.sostavscepok
WHERE number_scepki NOT IN (SELECT number_scepki FROM public.scepki);

-- 2. Восстановление внешнего ключа:
ALTER TABLE public.sostavscepok
ADD CONSTRAINT fk_sostavscepok_scepki FOREIGN KEY (number_scepki)
    REFERENCES public.scepki (number_scepki)
    ON UPDATE CASCADE
    ON DELETE CASCADE;

-- 3. Контрольная проверка: выявление нарушений (должна вернуть 0 строк):
SELECT 
    s.tramvai_number,
    s.number_scepki
FROM public.sostavscepok s
LEFT JOIN public.scepki c ON s.number_scepki = c.number_scepki
WHERE c.number_scepki IS NULL;
