import { useRouter } from 'next/router';
import { useState, useEffect } from 'react';
import { createClientComponentClient } from '@supabase/auth-helpers-nextjs';

// Types
interface Attendee {
  id: string;
  name: string;
  email: string;
  rsvp_status: 'yes' | 'no' | 'maybe' | 'pending';
}

interface Event {
  id: string;
  title: string;
  date: string;
  location: string;
  description: string;
  duration: number;
  created_at: string;
  creator_id: string;
  is_private: boolean;
  attendees: Attendee[];
}

export default function HangoutPage() {
  const router = useRouter();
  const { id, token } = router.query;
  const [event, setEvent] = useState<Event | null>(null);
  const [loading, setLoading] = useState(true);
  const [phoneNumber, setPhoneNumber] = useState('');
  const [isVerifying, setIsVerifying] = useState(false);
  const [verificationError, setVerificationError] = useState<string | null>(null);
  const [isVerified, setIsVerified] = useState(false);
  const supabase = createClientComponentClient();

  useEffect(() => {
    async function fetchEvent() {
      if (!id || !token || !isVerified) return;

      try {
        const { data, error } = await supabase
          .from('events')
          .select(`
            *,
            event_attendees (*)
          `)
          .eq('id', id)
          .single();

        if (error) {
          console.error('Error fetching event:', error);
          return;
        }

        setEvent(data);
      } finally {
        setLoading(false);
      }
    }

    fetchEvent();
  }, [id, token, isVerified, supabase]);

  const handleVerifyPhone = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsVerifying(true);
    setVerificationError(null);

    try {
      const { data, error } = await supabase
        .rpc('verify_invite_phone', {
          p_token: token,
          p_phone: phoneNumber,
          p_ip: '127.0.0.1' // In production, you'd want to get this from the server
        });

      if (error) throw error;

      if (data) {
        setIsVerified(true);
      } else {
        setVerificationError('Invalid phone number or token. Please try again.');
      }
    } catch (error) {
      console.error('Error verifying phone:', error);
      setVerificationError('An error occurred during verification. Please try again.');
    } finally {
      setIsVerifying(false);
    }
  };

  if (!token) {
    return (
      <div className="min-h-screen bg-gradient-to-b from-white to-gray-50 flex items-center justify-center">
        <div className="text-center">
          <h1 className="text-2xl font-bold text-gray-800 mb-2">Invalid Invite Link</h1>
          <p className="text-gray-600">This invite link appears to be invalid.</p>
        </div>
      </div>
    );
  }

  if (!isVerified) {
    return (
      <div className="min-h-screen bg-gradient-to-b from-white to-gray-50 flex items-center justify-center">
        <div className="max-w-md w-full mx-4">
          <div className="bg-white rounded-2xl shadow-sm p-6">
            <h1 className="text-2xl font-bold text-gray-800 mb-4">Verify Your Phone</h1>
            <p className="text-gray-600 mb-6">
              Please enter your phone number to view the event details.
            </p>
            <form onSubmit={handleVerifyPhone}>
              <div className="mb-4">
                <label htmlFor="phone" className="block text-sm font-medium text-gray-700 mb-1">
                  Phone Number
                </label>
                <input
                  type="tel"
                  id="phone"
                  value={phoneNumber}
                  onChange={(e) => setPhoneNumber(e.target.value)}
                  placeholder="+1 (555) 555-5555"
                  className="w-full px-4 py-2 border border-gray-300 rounded-xl focus:ring-2 focus:ring-[#FF7E45] focus:border-transparent outline-none"
                  required
                />
              </div>
              {verificationError && (
                <div className="mb-4 text-red-600 text-sm">{verificationError}</div>
              )}
              <button
                type="submit"
                disabled={isVerifying}
                className="w-full px-4 py-3 bg-[#FF7E45] text-white rounded-xl hover:bg-[#FF5126] transition-colors disabled:opacity-50"
              >
                {isVerifying ? 'Verifying...' : 'Verify Phone Number'}
              </button>
            </form>
          </div>
        </div>
      </div>
    );
  }

  if (loading) {
    return (
      <div className="min-h-screen bg-gradient-to-b from-white to-gray-50 flex items-center justify-center">
        <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-[#FF7E45]"></div>
      </div>
    );
  }

  if (!event) {
    return (
      <div className="min-h-screen bg-gradient-to-b from-white to-gray-50 flex items-center justify-center">
        <div className="text-center">
          <h1 className="text-2xl font-bold text-gray-800 mb-2">Event Not Found</h1>
          <p className="text-gray-600">This event may have been deleted or is private.</p>
        </div>
      </div>
    );
  }

  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    return date.toLocaleDateString('en-US', {
      weekday: 'long',
      year: 'numeric',
      month: 'long',
      day: 'numeric',
      hour: 'numeric',
      minute: '2-digit',
    });
  };

  const addToGoogleCalendar = () => {
    const startDate = new Date(event.date);
    const endDate = new Date(startDate.getTime() + event.duration * 60000);
    
    const url = new URL('https://calendar.google.com/calendar/render');
    url.searchParams.append('action', 'TEMPLATE');
    url.searchParams.append('text', event.title);
    url.searchParams.append('dates', `${startDate.toISOString().replace(/[-:]/g, '').split('.')[0]}Z/${endDate.toISOString().replace(/[-:]/g, '').split('.')[0]}Z`);
    url.searchParams.append('location', event.location);
    url.searchParams.append('details', event.description || '');
    
    window.open(url.toString(), '_blank');
  };

  const addToAppleCalendar = () => {
    const startDate = new Date(event.date);
    const endDate = new Date(startDate.getTime() + event.duration * 60000);
    
    const url = new URL('webcal://calendar.google.com/calendar/ical');
    url.searchParams.append('action', 'TEMPLATE');
    url.searchParams.append('text', event.title);
    url.searchParams.append('dates', `${startDate.toISOString().replace(/[-:]/g, '').split('.')[0]}Z/${endDate.toISOString().replace(/[-:]/g, '').split('.')[0]}Z`);
    url.searchParams.append('location', event.location);
    url.searchParams.append('details', event.description || '');
    
    window.location.href = url.toString();
  };

  return (
    <div className="min-h-screen bg-gradient-to-b from-white to-gray-50">
      <div className="max-w-2xl mx-auto p-6">
        {/* Event Header */}
        <div className="bg-white rounded-2xl shadow-sm p-6 mb-6">
          <h1 className="text-3xl font-bold text-gray-800 mb-4">{event.title}</h1>
          <div className="flex items-center text-gray-600 mb-4">
            <svg className="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
            </svg>
            <span>{formatDate(event.date)}</span>
          </div>
          <div className="flex items-center text-gray-600">
            <svg className="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
            </svg>
            <span>{event.location}</span>
          </div>
        </div>

        {/* Calendar Buttons */}
        <div className="bg-white rounded-2xl shadow-sm p-6 mb-6">
          <h2 className="text-xl font-semibold text-gray-800 mb-4">Add to Calendar</h2>
          <div className="flex flex-col space-y-3">
            <button
              onClick={addToGoogleCalendar}
              className="flex items-center justify-center px-4 py-3 bg-[#FF7E45] text-white rounded-xl hover:bg-[#FF5126] transition-colors"
            >
              Add to Google Calendar
            </button>
            <button
              onClick={addToAppleCalendar}
              className="flex items-center justify-center px-4 py-3 border-2 border-[#FF7E45] text-[#FF7E45] rounded-xl hover:bg-[#FFF5F0] transition-colors"
            >
              Add to Apple Calendar
            </button>
          </div>
        </div>

        {/* Attendees */}
        <div className="bg-white rounded-2xl shadow-sm p-6">
          <h2 className="text-xl font-semibold text-gray-800 mb-4">Who's Coming?</h2>
          <div className="space-y-4">
            {event.attendees?.map((attendee) => (
              <div key={attendee.id} className="flex items-center justify-between">
                <div className="flex items-center">
                  <div className="w-10 h-10 rounded-full bg-[#FF7E45] flex items-center justify-center text-white font-medium">
                    {attendee.name.charAt(0).toUpperCase()}
                  </div>
                  <span className="ml-3 text-gray-800">{attendee.name}</span>
                </div>
                <span className={`px-3 py-1 rounded-full text-sm ${
                  attendee.rsvp_status === 'yes' ? 'bg-green-100 text-green-800' :
                  attendee.rsvp_status === 'no' ? 'bg-red-100 text-red-800' :
                  attendee.rsvp_status === 'maybe' ? 'bg-yellow-100 text-yellow-800' :
                  'bg-gray-100 text-gray-800'
                }`}>
                  {attendee.rsvp_status.charAt(0).toUpperCase() + attendee.rsvp_status.slice(1)}
                </span>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
} 