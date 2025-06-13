-- ============================================================================
-- COMPLETE DATABASE FIX FOR BOOKBRIDGE PROJECT
-- ============================================================================

-- First, let's check what data exists in both tables
SELECT 'Books Categories' as table_info, category, COUNT(*) as count 
FROM books 
WHERE category IS NOT NULL
GROUP BY category 
ORDER BY count DESC;

SELECT 'Books Status' as table_info, status, COUNT(*) as count 
FROM books 
WHERE status IS NOT NULL
GROUP BY status 
ORDER BY count DESC;

SELECT 'Book Requests Status' as table_info, status, COUNT(*) as count 
FROM book_requests 
WHERE status IS NOT NULL
GROUP BY status 
ORDER BY count DESC;

-- ============================================================================
-- FIX 1: BOOKS CATEGORY CONSTRAINT (This is causing your donation error)
-- ============================================================================

-- Check current category constraint
SELECT conname, pg_get_constraintdef(oid) 
FROM pg_constraint 
WHERE conrelid = 'books'::regclass AND conname = 'books_category_check';

-- Drop existing category constraint if it exists
ALTER TABLE books DROP CONSTRAINT IF EXISTS books_category_check;

-- Update any invalid category values to match your UI categories
-- Based on your UI, these are the valid categories: Academic, Stories, Technology, Self-Help, Science

UPDATE books SET category = 'Academic' 
WHERE LOWER(TRIM(category)) IN ('academic', 'academics', 'education', 'educational');

UPDATE books SET category = 'Stories' 
WHERE LOWER(TRIM(category)) IN ('stories', 'story', 'fiction', 'novel', 'novels');

UPDATE books SET category = 'Technology' 
WHERE LOWER(TRIM(category)) IN ('technology', 'tech', 'programming', 'computer', 'it');

UPDATE books SET category = 'Self-Help' 
WHERE LOWER(TRIM(category)) IN ('self-help', 'selfhelp', 'self help', 'personal development', 'motivation');

UPDATE books SET category = 'Science' 
WHERE LOWER(TRIM(category)) IN ('science', 'sciences', 'scientific', 'research');

-- Set any remaining invalid categories to 'Academic' as default
UPDATE books SET category = 'Academic' 
WHERE category IS NULL OR category NOT IN ('Academic', 'Stories', 'Technology', 'Self-Help', 'Science');

-- Add the correct category constraint
ALTER TABLE books ADD CONSTRAINT books_category_check 
CHECK (category IN ('Academic', 'Stories', 'Technology', 'Self-Help', 'Science'));

-- ============================================================================
-- FIX 2: BOOKS STATUS CONSTRAINT (Improved from your existing code)
-- ============================================================================

-- Check what status values exist in books table
SELECT status, COUNT(*) as count 
FROM books 
GROUP BY status 
ORDER BY count DESC;

-- Update any invalid status values
UPDATE books 
SET status = 'available' 
WHERE status IS NULL OR status NOT IN ('available', 'donated', 'requested', 'unavailable');

-- Drop and recreate books status constraint
ALTER TABLE books DROP CONSTRAINT IF EXISTS books_status_check;
ALTER TABLE books ADD CONSTRAINT books_status_check 
CHECK (status IN ('available', 'donated', 'requested', 'unavailable'));

-- ============================================================================
-- FIX 3: BOOK REQUESTS STATUS CONSTRAINT (Your existing code improved)
-- ============================================================================

-- Check what status values exist in book_requests table
SELECT status, COUNT(*) as count 
FROM book_requests 
GROUP BY status 
ORDER BY count DESC;

-- Update any rows with NULL or invalid status values to 'pending'
UPDATE book_requests 
SET status = 'pending' 
WHERE status IS NULL OR status NOT IN ('pending', 'accepted', 'rejected', 'completed', 'cancelled');

-- Drop and recreate book_requests status constraint
ALTER TABLE book_requests DROP CONSTRAINT IF EXISTS book_requests_status_check;
ALTER TABLE book_requests ADD CONSTRAINT book_requests_status_check 
CHECK (status IN ('pending', 'accepted', 'rejected', 'completed', 'cancelled'));

-- ============================================================================
-- FIX 4: ADD MISSING CONSTRAINTS AND INDEXES
-- ============================================================================

-- Add condition constraint for books (if it doesn't exist)
ALTER TABLE books DROP CONSTRAINT IF EXISTS books_condition_check;
ALTER TABLE books ADD CONSTRAINT books_condition_check 
CHECK (condition IN ('New', 'Like New', 'Very Good', 'Good', 'Fair'));

-- Add useful indexes for better performance
CREATE INDEX IF NOT EXISTS idx_books_category ON books(category);
CREATE INDEX IF NOT EXISTS idx_books_status ON books(status);
CREATE INDEX IF NOT EXISTS idx_book_requests_status ON book_requests(status);
CREATE INDEX IF NOT EXISTS idx_books_created_at ON books(created_at);
CREATE INDEX IF NOT EXISTS idx_book_requests_created_at ON book_requests(created_at);

-- ============================================================================
-- FIX 5: VERIFY ALL CONSTRAINTS
-- ============================================================================

-- Check all constraints on books table
SELECT conname, pg_get_constraintdef(oid) 
FROM pg_constraint 
WHERE conrelid = 'books'::regclass;

-- Check all constraints on book_requests table
SELECT conname, pg_get_constraintdef(oid) 
FROM pg_constraint 
WHERE conrelid = 'book_requests'::regclass;

-- ============================================================================
-- FIX 6: TEST DATA INSERTION
-- ============================================================================

-- Test inserting a book with valid data (this should work after the fixes)
-- Remove the comment below to test:
/*
INSERT INTO books (title, author, category, status, condition, description, created_at)
VALUES (
    'Test Book', 
    'Test Author', 
    'Academic',  -- This should now work
    'available', 
    'Good', 
    'Test description', 
    NOW()
);
*/

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Final verification - these should all return data without errors
SELECT 'Books by Category' as info, category, COUNT(*) 
FROM books 
GROUP BY category;

SELECT 'Books by Status' as info, status, COUNT(*) 
FROM books 
GROUP BY status;

SELECT 'Book Requests by Status' as info, status, COUNT(*) 
FROM book_requests 
GROUP BY status;