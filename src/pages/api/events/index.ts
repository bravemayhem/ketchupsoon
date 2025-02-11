import { NextApiRequest, NextApiResponse } from 'next'
import { supabase } from '@/lib/supabase/client'

export default async function handler(
  req: NextApiRequest,
  res: NextApiResponse
) {
  if (req.method === 'POST') {
    try {
      const {
        title,
        date,
        location,
        description,
        duration,
        creator_id,
        attendees
      } = req.body

      // Create event
      const { data: event, error: eventError } = await supabase
        .from('events')
        .insert([
          {
            title,
            date,
            location,
            description,
            duration,
            creator_id,
            is_private: false
          }
        ])
        .select()
        .single()

      if (eventError) throw eventError

      // Add attendees
      if (attendees && attendees.length > 0) {
        const { error: attendeesError } = await supabase
          .from('event_attendees')
          .insert(
            attendees.map((attendee: any) => ({
              event_id: event.id,
              name: attendee.name,
              email: attendee.email,
              phone: attendee.phone,
              rsvp_status: 'pending'
            }))
          )

        if (attendeesError) throw attendeesError
      }

      res.status(200).json(event)
    } catch (error) {
      console.error('Error creating event:', error)
      res.status(500).json({ error: 'Error creating event' })
    }
  } else {
    res.setHeader('Allow', ['POST'])
    res.status(405).end(`Method ${req.method} Not Allowed`)
  }
} 