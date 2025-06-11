
import React, { useState, useEffect } from 'react';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Heart, BookOpen, User, Calendar, Eye, Trash2 } from 'lucide-react';
import { supabase } from '@/integrations/supabase/client';
import { useToast } from '@/hooks/use-toast';

interface DonatedBook {
  id: string;
  title: string;
  author: string;
  category: string;
  description: string;
  status: string;
  createdat: string;
  condition: string;
  is_free_to_read: boolean;
}

export const MyDonations = () => {
  const [donatedBooks, setDonatedBooks] = useState<DonatedBook[]>([]);
  const [loading, setLoading] = useState(true);
  const { toast } = useToast();

  useEffect(() => {
    fetchDonatedBooks();
  }, []);

  const fetchDonatedBooks = async () => {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return;

      const { data, error } = await supabase
        .from('books')
        .select('*')
        .eq('donorid', user.id)
        .order('createdat', { ascending: false });

      if (error) throw error;

      setDonatedBooks(data || []);
    } catch (error) {
      console.error('Error fetching donated books:', error);
    }
    setLoading(false);
  };

  const handleDeleteBook = async (bookId: string) => {
    try {
      // Check if there are any pending requests for this book
      const { data: requests } = await supabase
        .from('book_requests')
        .select('id')
        .eq('book_id', bookId)
        .eq('status', 'pending');

      if (requests && requests.length > 0) {
        toast({
          title: "Cannot delete",
          description: "This book has pending requests. Please handle them first.",
          variant: "destructive",
        });
        return;
      }

      const { error } = await supabase
        .from('books')
        .delete()
        .eq('id', bookId);

      if (error) throw error;

      setDonatedBooks(prev => prev.filter(book => book.id !== bookId));

      toast({
        title: "Book removed",
        description: "The book has been successfully removed from your donations.",
      });
    } catch (error: any) {
      toast({
        title: "Error",
        description: error.message,
        variant: "destructive",
      });
    }
  };

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'available':
        return <Badge className="bg-green-500">Available</Badge>;
      case 'requested':
        return <Badge variant="outline">Requested</Badge>;
      case 'donated':
        return <Badge variant="secondary">Completed</Badge>;
      default:
        return <Badge variant="outline">{status}</Badge>;
    }
  };

  if (loading) {
    return (
      <div className="container mx-auto px-4 py-8">
        <div className="text-center">Loading...</div>
      </div>
    );
  }

  return (
    <div className="container mx-auto px-4 py-8">
      <div className="mb-8">
        <h1 className="text-3xl font-bold mb-2 flex items-center">
          <Heart className="h-8 w-8 mr-2 text-primary" />
          My Donations
        </h1>
        <p className="text-muted-foreground">
          Track and manage the books you've donated to the community.
        </p>
      </div>

      {donatedBooks.length === 0 ? (
        <Card>
          <CardContent className="text-center py-12">
            <Heart className="h-16 w-16 mx-auto text-muted-foreground mb-4" />
            <h3 className="text-xl font-semibold mb-2">No donations yet</h3>
            <p className="text-muted-foreground mb-4">
              You haven't donated any books yet. Start sharing knowledge with the community!
            </p>
            <Button>
              <BookOpen className="h-4 w-4 mr-2" />
              Donate Your First Book
            </Button>
          </CardContent>
        </Card>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {donatedBooks.map((book) => (
            <Card key={book.id} className="hover:shadow-lg transition-shadow">
              <CardHeader>
                <div className="flex items-start justify-between">
                  <div className="flex-1">
                    <CardTitle className="text-lg mb-2">{book.title}</CardTitle>
                    <div className="flex items-center text-muted-foreground mb-2">
                      <User className="h-4 w-4 mr-1" />
                      <span className="text-sm">by {book.author}</span>
                    </div>
                    <Badge variant="secondary" className="mb-2">
                      {book.category}
                    </Badge>
                  </div>
                  <div className="flex flex-col items-end gap-2">
                    {getStatusBadge(book.status)}
                    {book.is_free_to_read && (
                      <Badge variant="outline" className="bg-blue-50 text-blue-700 border-blue-200">
                        <Eye className="h-3 w-3 mr-1" />
                        Free Read
                      </Badge>
                    )}
                  </div>
                </div>
              </CardHeader>
              <CardContent>
                <p className="text-muted-foreground text-sm mb-4 line-clamp-3">
                  {book.description}
                </p>
                <div className="flex items-center justify-between text-sm text-muted-foreground mb-4">
                  <div className="flex items-center">
                    <Calendar className="h-4 w-4 mr-1" />
                    {new Date(book.createdat).toLocaleDateString()}
                  </div>
                  <span>Condition: {book.condition}</span>
                </div>
                
                <div className="flex gap-2">
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => handleDeleteBook(book.id)}
                    className="flex-1"
                  >
                    <Trash2 className="h-4 w-4 mr-2" />
                    Remove
                  </Button>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      )}
    </div>
  );
};
