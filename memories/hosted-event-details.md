# Hosted Event Details Feature Plan

## Overview
Create a web-based event details system that allows both app users and non-app users to view hangout details and add events to their calendars.

## Goals
- Provide a seamless experience for non-app users to view and add events
- Maintain privacy and security of event details
- Enable easy calendar integration for any calendar type
- Create a professional and branded web presence

## Infrastructure Requirements

### Hosting & Domain
- [x] Domain name (already owned)
- [ ] Vercel account for hosting
- [ ] Supabase account for database
- [ ] SSL certificate setup

### Technical Stack
- [x] Next.js web application
- [x] Supabase (PostgreSQL) database
- [x] TypeScript for type safety
- [x] Tailwind CSS for styling
- [ ] Authentication system

## Database Schema

### Events Table
```sql
events {
  id: uuid (primary key)
  title: string
  date: timestamp
  location: string
  description: string
  duration: integer
  created_at: timestamp
  updated_at: timestamp
  creator_id: string (reference to iOS app user)
  is_private: boolean
}

event_attendees {
  id: uuid (primary key)
  event_id: uuid (foreign key)
  name: string
  email: string
  phone: string
  rsvp_status: string
  created_at: timestamp
}
```

## API Endpoints Required

### iOS App Endpoints
- [ ] POST /api/events - Create new event
- [ ] PUT /api/events/:id - Update event
- [ ] DELETE /api/events/:id - Delete event
- [ ] POST /api/events/:id/attendees - Add attendees

### Web Endpoints
- [ ] GET /api/events/:id - Get event details
- [ ] GET /api/events/:id/ics - Get ICS file
- [ ] POST /api/events/:id/rsvp - Update RSVP status

## Web Features
- [ ] Event detail page (/hangout/[id])
- [ ] Add to calendar buttons
  - [ ] Google Calendar
  - [ ] Apple Calendar
  - [ ] Outlook
  - [ ] Download ICS
- [ ] RSVP functionality
- [ ] Mobile-responsive design
- [ ] Share buttons

## iOS App Changes Required
- [ ] Update CalendarManager to create web events
- [ ] Modify event creation flow to include web link
- [ ] Update sharing messages to include web link
- [ ] Add event sync functionality

## Security Considerations
- [ ] Event access tokens
- [ ] Rate limiting
- [ ] Data encryption
- [ ] Privacy controls
- [ ] GDPR compliance

## Testing Requirements
- [ ] API endpoint tests
- [ ] Web UI tests
- [ ] iOS integration tests
- [ ] Security testing
- [ ] Load testing

## Launch Checklist
- [ ] Set up development environment
- [ ] Create basic Next.js project
- [ ] Set up Supabase database
- [ ] Configure domain with Vercel
- [ ] Implement basic API endpoints
- [ ] Create web UI
- [ ] Update iOS app
- [ ] Testing
- [ ] Security audit
- [ ] Production deployment

## Future Enhancements
- Event comments/discussion
- Photo sharing
- Calendar sync
- Push notifications
- Event templates
- Recurring events

## Questions to Resolve
1. How to handle event privacy levels?
2. Should we allow non-app users to create events?
3. How to handle timezone differences?
4. Data retention policy?
5. Backup strategy?

## Progress Tracking
- [x] Infrastructure Setup (100%)
  - Set up Next.js project with TypeScript
  - Configured Tailwind CSS and PostCSS
  - Installed necessary dependencies
- [x] Database Implementation (50%)
  - Created initial events table
  - Set up event_attendees table
  - Added necessary columns and constraints
- [ ] API Development (0%)
- [ ] Web UI Development (0%)
- [ ] iOS Integration (0%)
- [ ] Testing (0%)
- [ ] Security Review (0%)
- [ ] Documentation (10%)

## Recent Updates
### 2024-03-XX
1. Set up Next.js project with TypeScript support
2. Configured Tailwind CSS and resolved dependency issues
3. Created and modified database schema for events and attendees
4. Added necessary columns for tracking event creation and updates

## Next Steps
1. Implement basic API endpoints for event creation and retrieval
2. Create the event detail page layout (/hangout/[id])
3. Set up Supabase authentication
4. Begin work on the RSVP functionality
5. Create calendar integration endpoints

## Notes
- Keep initial implementation focused and simple
- Plan for scalability from the start
- Prioritize user experience
- Maintain consistent branding with iOS app 