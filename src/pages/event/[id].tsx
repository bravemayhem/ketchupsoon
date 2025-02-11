import { GetServerSideProps } from 'next'
import { createClient } from '@supabase/supabase-js'
import { useState } from 'react'

interface Event {
  id: string
  title: string
  date: string
  location: string
  description: string
  created_by: string
}

interface Attendee {
  id: string
  event_id: string
  attendee_id: string
  status: 'yes' | 'no' | 'maybe'
  name: string
  email: string
}

interface Props {
  event: Event
  attendees: Attendee[]
}

export default function EventPage({ event, attendees }: Props) {
  const [name, setName] = useState('')
  const [email, setEmail] = useState('')
  const [status, setStatus] = useState<'yes' | 'no' | 'maybe'>('yes')
  const [message, setMessage] = useState('')

  const handleRSVP = async (e: React.FormEvent) => {
    e.preventDefault()
    const supabase = createClient(
      process.env.NEXT_PUBLIC_SUPABASE_URL!,
      process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
    )

    const { error } = await supabase.from('event_attendees').insert([
      {
        event_id: event.id,
        name,
        email,
        status
      }
    ])

    if (error) {
      console.error('Error submitting RSVP:', error)
      setMessage('Error submitting RSVP. Please try again.')
      return
    }

    setMessage('RSVP submitted successfully!')
    setName('')
    setEmail('')
    window.location.reload()
  }

  return (
    <div className="min-h-screen bg-gray-100">
      <div className="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
        <div className="px-4 py-6 sm:px-0">
          <div className="bg-white shadow rounded-lg overflow-hidden">
            <div className="px-4 py-5 sm:p-6">
              <h1 className="text-3xl font-bold text-gray-900 mb-4">
                {event.title}
              </h1>
              <div className="space-y-3">
                <p className="text-lg text-gray-600">
                  <span className="font-semibold">Date:</span>{' '}
                  {new Date(event.date).toLocaleString()}
                </p>
                <p className="text-lg text-gray-600">
                  <span className="font-semibold">Location:</span> {event.location}
                </p>
                <p className="text-lg text-gray-600">{event.description}</p>
              </div>
            </div>
          </div>

          <div className="mt-8 bg-white shadow rounded-lg overflow-hidden">
            <div className="px-4 py-5 sm:p-6">
              <h2 className="text-2xl font-bold text-gray-900 mb-4">RSVP</h2>
              <form onSubmit={handleRSVP} className="space-y-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700">
                    Name
                  </label>
                  <input
                    type="text"
                    required
                    className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                    value={name}
                    onChange={(e) => setName(e.target.value)}
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700">
                    Email
                  </label>
                  <input
                    type="email"
                    required
                    className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700">
                    Status
                  </label>
                  <select
                    className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                    value={status}
                    onChange={(e) => setStatus(e.target.value as 'yes' | 'no' | 'maybe')}
                  >
                    <option value="yes">Yes, I'll be there!</option>
                    <option value="no">No, I can't make it</option>
                    <option value="maybe">Maybe</option>
                  </select>
                </div>
                <button
                  type="submit"
                  className="bg-indigo-600 hover:bg-indigo-700 text-white font-bold py-2 px-4 rounded"
                >
                  Submit RSVP
                </button>
              </form>
              {message && (
                <p className="mt-4 text-sm text-gray-600">{message}</p>
              )}
            </div>
          </div>

          <div className="mt-8 bg-white shadow rounded-lg overflow-hidden">
            <div className="px-4 py-5 sm:p-6">
              <h2 className="text-2xl font-bold text-gray-900 mb-4">
                Attendees ({attendees.length})
              </h2>
              <div className="space-y-4">
                {attendees.map((attendee) => (
                  <div
                    key={attendee.id}
                    className="flex items-center justify-between border-b pb-4"
                  >
                    <div>
                      <p className="font-medium">{attendee.name}</p>
                      <p className="text-sm text-gray-500">{attendee.email}</p>
                    </div>
                    <span
                      className={`px-2 py-1 rounded-full text-sm ${
                        attendee.status === 'yes'
                          ? 'bg-green-100 text-green-800'
                          : attendee.status === 'no'
                          ? 'bg-red-100 text-red-800'
                          : 'bg-yellow-100 text-yellow-800'
                      }`}
                    >
                      {attendee.status}
                    </span>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}

export const getServerSideProps: GetServerSideProps = async ({ params }) => {
  const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
  )

  const { data: event, error: eventError } = await supabase
    .from('events')
    .select('*')
    .eq('id', params?.id)
    .single()

  if (eventError || !event) {
    return {
      notFound: true,
    }
  }

  const { data: attendees, error: attendeesError } = await supabase
    .from('event_attendees')
    .select('*')
    .eq('event_id', event.id)

  if (attendeesError) {
    console.error('Error fetching attendees:', attendeesError)
  }

  return {
    props: {
      event,
      attendees: attendees || [],
    },
  }
} 