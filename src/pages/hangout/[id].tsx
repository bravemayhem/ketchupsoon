import React, { useState } from 'react'
import { GetServerSideProps } from 'next'
import { supabase } from '@/lib/supabase/client'
import { format } from 'date-fns'

interface Event {
  id: string
  title: string
  date: string
  location: string
  description: string
  duration: number
  created_by: string
}

interface Attendee {
  id: string
  name: string
  email: string
  rsvp_status: 'yes' | 'no' | 'maybe'
}

interface Props {
  event: Event | null
  attendees: Attendee[]
  error?: string
}

export default function HangoutPage({ event, attendees, error }: Props) {
  const [rsvpForm, setRsvpForm] = useState({
    name: '',
    email: '',
    status: 'yes' as 'yes' | 'no' | 'maybe'
  })
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [submitError, setSubmitError] = useState('')
  const [submitSuccess, setSubmitSuccess] = useState(false)

  if (error) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <h1 className="text-2xl font-bold text-red-600">Error</h1>
          <p className="mt-2">{error}</p>
        </div>
      </div>
    )
  }

  if (!event) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <h1 className="text-2xl font-bold">Event Not Found</h1>
          <p className="mt-2">This event may have been deleted or does not exist.</p>
        </div>
      </div>
    )
  }

  const handleRSVP = async (e: React.FormEvent) => {
    e.preventDefault()
    setIsSubmitting(true)
    setSubmitError('')
    setSubmitSuccess(false)

    try {
      const { error } = await supabase
        .from('event_attendees')
        .insert([
          {
            event_id: event.id,
            name: rsvpForm.name,
            email: rsvpForm.email,
            rsvp_status: rsvpForm.status
          }
        ])

      if (error) throw error

      setSubmitSuccess(true)
      setRsvpForm({ name: '', email: '', status: 'yes' })
    } catch (error) {
      setSubmitError('Failed to submit RSVP. Please try again.')
    } finally {
      setIsSubmitting(false)
    }
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <main className="max-w-3xl mx-auto py-12 px-4">
        <div className="bg-white rounded-lg shadow-lg overflow-hidden">
          <div className="px-6 py-8">
            <h1 className="text-3xl font-bold text-gray-900">{event.title}</h1>
            
            <div className="mt-6 space-y-4">
              <div>
                <h2 className="text-sm font-medium text-gray-500">When</h2>
                <p className="mt-1 text-lg text-gray-900">
                  {format(new Date(event.date), 'EEEE, MMMM d, yyyy h:mm a')}
                  {event.duration && ` (${event.duration} minutes)`}
                </p>
              </div>

              <div>
                <h2 className="text-sm font-medium text-gray-500">Where</h2>
                <p className="mt-1 text-lg text-gray-900">{event.location}</p>
              </div>

              {event.description && (
                <div>
                  <h2 className="text-sm font-medium text-gray-500">Details</h2>
                  <p className="mt-1 text-lg text-gray-900">{event.description}</p>
                </div>
              )}
            </div>

            <div className="mt-8">
              <h2 className="text-lg font-semibold text-gray-900">RSVP</h2>
              {submitSuccess ? (
                <div className="mt-4 p-4 bg-green-50 rounded-md">
                  <p className="text-green-700">Thanks for your RSVP! We've recorded your response.</p>
                </div>
              ) : (
                <form onSubmit={handleRSVP} className="mt-4 space-y-4">
                  <div>
                    <label htmlFor="name" className="block text-sm font-medium text-gray-700">
                      Name
                    </label>
                    <input
                      type="text"
                      id="name"
                      required
                      className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                      value={rsvpForm.name}
                      onChange={(e) => setRsvpForm({ ...rsvpForm, name: e.target.value })}
                    />
                  </div>

                  <div>
                    <label htmlFor="email" className="block text-sm font-medium text-gray-700">
                      Email
                    </label>
                    <input
                      type="email"
                      id="email"
                      required
                      className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                      value={rsvpForm.email}
                      onChange={(e) => setRsvpForm({ ...rsvpForm, email: e.target.value })}
                    />
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700">
                      Will you attend?
                    </label>
                    <div className="mt-2 space-x-4">
                      {['yes', 'no', 'maybe'].map((status) => (
                        <label key={status} className="inline-flex items-center">
                          <input
                            type="radio"
                            className="form-radio text-indigo-600"
                            name="status"
                            value={status}
                            checked={rsvpForm.status === status}
                            onChange={(e) => setRsvpForm({ ...rsvpForm, status: e.target.value as 'yes' | 'no' | 'maybe' })}
                          />
                          <span className="ml-2 capitalize">{status}</span>
                        </label>
                      ))}
                    </div>
                  </div>

                  {submitError && (
                    <div className="text-red-600 text-sm">{submitError}</div>
                  )}

                  <button
                    type="submit"
                    disabled={isSubmitting}
                    className="w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:opacity-50"
                  >
                    {isSubmitting ? 'Submitting...' : 'Submit RSVP'}
                  </button>
                </form>
              )}
            </div>

            {attendees.length > 0 && (
              <div className="mt-8">
                <h2 className="text-lg font-semibold text-gray-900">Who's Coming</h2>
                <div className="mt-4 space-y-2">
                  {attendees.map((attendee) => (
                    <div key={attendee.id} className="flex items-center justify-between py-2">
                      <div>
                        <span className="text-gray-900 font-medium">{attendee.name}</span>
                        <span className="ml-2 text-sm text-gray-500">{attendee.email}</span>
                      </div>
                      <span className={`text-sm capitalize px-2 py-1 rounded-full ${
                        attendee.rsvp_status === 'yes' 
                          ? 'bg-green-100 text-green-800'
                          : attendee.rsvp_status === 'no'
                          ? 'bg-red-100 text-red-800'
                          : 'bg-yellow-100 text-yellow-800'
                      }`}>
                        {attendee.rsvp_status}
                      </span>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </div>
        </div>
      </main>
    </div>
  )
}

export const getServerSideProps: GetServerSideProps = async ({ params }) => {
  try {
    // Fetch event details
    const { data: event, error: eventError } = await supabase
      .from('events')
      .select('*')
      .eq('id', params?.id)
      .single()

    if (eventError) throw eventError

    // Fetch attendees
    const { data: attendees, error: attendeesError } = await supabase
      .from('event_attendees')
      .select('*')
      .eq('event_id', params?.id)

    if (attendeesError) throw attendeesError

    return {
      props: {
        event,
        attendees: attendees || []
      }
    }
  } catch (error) {
    console.error('Error fetching event:', error)
    return {
      props: {
        event: null,
        attendees: [],
        error: 'Failed to load event'
      }
    }
  }
} 