import React from 'react';

const RenderRequirementMessage = ({ text, theme }) => {
  if (!text) return null;

  const skillKeywords = [
    'java', 'react', 'typescript', 'spring boot', 'kafka', 'redis', 'postgresql', 
    'kubernetes', 'docker', 'go', 'python', 'aws', 'gcp', 'microservices',
    'rest api', 'grpc', 'elasticsearch', 'mongodb', 'mysql', 'aurora',
    'node', 'express', 'sql', 'nosql', 'git', 'linux'
  ];
  
  const counts = {};
  const allText = text.toLowerCase();
  skillKeywords.forEach(skill => {
    const regex = new RegExp(`\\b${skill}\\b`, 'gi');
    const matches = allText.match(regex);
    if (matches) counts[skill] = matches.length;
  });
  
  const topSkillsList = Object.entries(counts)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 3)
    .map(e => e[0].toLowerCase());

  const isSkillHighlighted = (text) => {
    return topSkillsList.some(skill => text.toLowerCase().includes(skill));
  };

  return (
    <div style={{ whiteSpace: 'normal', wordBreak: 'break-word', lineHeight: '1.6' }}>
      {text.split('\n').map((line, idx) => {
        const trimmed = line.trim();
        
        // Skip empty lines but show spacing
        if (!trimmed) {
          return <div key={idx} style={{ height: '4px' }} />;
        }
        
        // Headers: ####, ###, ##, #
        if (trimmed.match(/^#+\s+/)) {
          const headerMatch = trimmed.match(/^#+/);
          const level = headerMatch ? headerMatch[0].length : 1;
          const headerText = trimmed.replace(/^#+\s+/, '').replace(/\*\*|\*|__/g, '');
          const fontSize = level === 1 ? '15px' : level === 2 ? '14px' : level === 3 ? '13px' : '12px';
          const fontWeight = level <= 2 ? 700 : 600;
          
          return (
            <div key={idx} style={{
              fontWeight,
              fontSize,
              marginTop: idx > 0 ? '14px' : '0px',
              marginBottom: '10px',
              color: theme.accent,
              textDecoration: level <= 2 ? 'underline' : 'none',
              paddingBottom: '6px',
              borderBottom: level <= 2 ? `2px solid ${theme.accent}40` : 'none'
            }}>
              {headerText}
            </div>
          );
        }
        
        // Bullet points: -, •, *, ✓, ✗
        if (trimmed.match(/^[-•*✓✗]\s+/) || trimmed.match(/^\d+\.\s+/)) {
          const content = trimmed.replace(/^[-•*✓✗]\s*/, '').replace(/^\d+\.\s*/, '');
          const isHighlight = isSkillHighlighted(content);
          
          return (
            <div key={idx} style={{
              marginLeft: '20px',
              marginBottom: '8px',
              padding: isHighlight ? '6px 10px' : '2px 0px',
              borderLeft: isHighlight ? `3px solid ${theme.accent}` : 'none',
              background: isHighlight ? `${theme.accent}20` : 'transparent',
              borderRadius: '3px',
              fontSize: '13px'
            }}>
              <span style={{ fontWeight: isHighlight ? 700 : 400, color: isHighlight ? theme.accent : theme.text }}>
                • {content.replace(/\*\*|\*|__/g, '')}
              </span>
            </div>
          );
        }
        
        // Bold text sections: **text**
        if (trimmed.includes('**')) {
          const parts = trimmed.split(/\*\*(.+?)\*\*/);
          const isHighlight = isSkillHighlighted(trimmed);
          
          return (
            <div key={idx} style={{
              marginBottom: '8px',
              lineHeight: '1.6',
              padding: isHighlight ? '6px 10px' : '0px',
              borderLeft: isHighlight ? `3px solid ${theme.accent}` : 'none',
              background: isHighlight ? `${theme.accent}20` : 'transparent',
              borderRadius: '3px',
              fontSize: '13px'
            }}>
              {parts.map((part, i) => {
                if (i % 2 === 1) {
                  // Bold part
                  return <span key={i} style={{ fontWeight: 700, color: theme.accent }}>{part}</span>;
                }
                // Regular part
                return <span key={i}>{part}</span>;
              })}
            </div>
          );
        }
        
        // Regular paragraph text
        const isHighlight = isSkillHighlighted(trimmed);
        return (
          <div key={idx} style={{
            marginBottom: '8px',
            lineHeight: '1.6',
            padding: isHighlight ? '6px 10px' : '0px',
            borderLeft: isHighlight ? `3px solid ${theme.accent}` : 'none',
            background: isHighlight ? `${theme.accent}20` : 'transparent',
            borderRadius: '3px',
            fontSize: '13px',
            color: theme.text
          }}>
            {trimmed}
          </div>
        );
      })}
    </div>
  );
};

export default RenderRequirementMessage;
