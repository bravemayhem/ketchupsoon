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

invites {
  id: uuid (primary key)
  event_id: uuid (foreign key)
  token: string (unique)
  expires_at: timestamp
  created_at: timestamp
}
```

## API Endpoints Required

### iOS App Endpoints
- [x] POST /api/events - Create new event
- [ ] PUT /api/events/:id - Update event
- [ ] DELETE /api/events/:id - Delete event
- [x] POST /api/events/:id/attendees - Add attendees
- [x] POST /api/events/:id/invites - Create invite token

### Web Endpoints
- [x] GET /api/events/:id - Get event details with token
- [ ] GET /api/events/:id/ics - Get ICS file
- [ ] POST /api/events/:id/rsvp - Update RSVP status

## Web Features
- [x] Event detail page (/hangout/[id])
- [ ] Add to calendar buttons
  - [ ] Google Calendar
  - [ ] Apple Calendar
  - [ ] Outlook
  - [ ] Download ICS
- [ ] RSVP functionality
- [x] Mobile-responsive design
- [ ] Share buttons

## iOS App Changes Required
- [x] Update CalendarManager to create web events
- [x] Modify event creation flow to include web link
- [x] Update sharing messages to include web link
- [x] Add event sync functionality
- [x] Store event link and token in Hangout model
- [x] Update HangoutCard to display and handle event links

## Security Considerations
- [x] Event access tokens
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
- [x] Set up development environment
- [x] Create basic Next.js project
- [x] Set up Supabase database
- [ ] Configure domain with Vercel
- [x] Implement basic API endpoints
- [x] Create web UI
- [x] Update iOS app
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
- [x] Database Implementation (100%)
  - Created initial events table
  - Set up event_attendees table
  - Added invites table
  - Added necessary columns and constraints
- [x] API Development (70%)
  - Implemented event creation
  - Implemented attendee creation
  - Implemented invite token system
- [x] Web UI Development (50%)
  - Created event detail page
  - Implemented token-based access
- [x] iOS Integration (90%)
  - Updated Hangout model
  - Implemented SupabaseManager
  - Updated CreateHangoutViewModel
  - Updated HangoutCard
- [ ] Testing (20%)
- [ ] Security Review (30%)
- [ ] Documentation (40%)

## Recent Updates
### 2024-03-XX
1. Implemented token-based access system for events
2. Updated iOS app to store and handle event links
3. Simplified event access by making HangoutCard tappable
4. Removed explicit "View Event Details" link for cleaner UI
5. Added event link and token storage to Hangout model
6. Updated SupabaseManager to handle invite token creation
7. Modified CreateHangoutViewModel to save event links with hangouts

## Next Steps
1. Complete RSVP functionality
2. Implement calendar integration endpoints
3. Add rate limiting to API endpoints
4. Set up production environment
5. Begin comprehensive testing

## Notes
- Keep initial implementation focused and simple
- Plan for scalability from the start
- Prioritize user experience
- Maintain consistent branding with iOS app 