module.exports = {
  cacheDirectory: true, // Enable babel cache
  presets: [
    ['@babel/preset-typescript', { 
      allowDeclareFields: true 
    }]
  ]
} 