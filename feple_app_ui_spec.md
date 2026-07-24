Feple Festival App UI Design Specification

Color Palette
Primary: #5BC0EB (Sky Blue) – Headers, buttons, accents
Secondary: #FDE74C (Sunny Yellow) – Stars, badges, highlights
Gradients: #5BC0EB→#A1DDF5, #FDE74C→#FFF5B1
Background: #FAFAFA (Pastel white)
Text: #333333 (Dark gray), #666666 (Light gray)

Target Style
Aesthetic: Kawaii / Cute / Pastel for 20s women
Radius: 24px (all cards/buttons)
Shadows: Soft (0 4px 12px rgba(91,192,235,0.15))
Fonts: Poppins Rounded, Noto Sans KR Bubble

Screen Components
Cards
```yaml
festival-card:
  background: linear-gradient(135deg, #5BC0EB15 0%, #FDE74C10 100%)
  border-radius: 20px
  shadow: 0 8px 24px rgba(0,0,0,0.1) 

cta-button:
  background: linear-gradient(45deg, #5BC0EB, #A1DDF5)
  border-radius: 16px
  text-shadow: none
  animation: bounce 0.3s ease

Micro-interactions
 Tap: scale(0.95) + #FDE74C glow
 Swipe: confetti burst (5 stars)
 Load: balloon float-up animation

Assets Needed
 festival-girl-mascot.png (waving, 200x200)
 star-yellow.png, heart-blue.png
 music-note-bubble.svg

 