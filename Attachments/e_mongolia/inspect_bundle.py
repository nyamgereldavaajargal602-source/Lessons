from pathlib import Path

def find_keywords():
    path = Path('bundle.js')
    if not path.exists():
        print('bundle.js not found')
        return
    text = path.read_text(errors='ignore')
    pats = ['Profile', 'profile', 'Home', 'home', 'More', 'more', 'Settings', 'settings', 'Dashboard', 'dashboard', 'Chat', 'chat', 'Supabase', 'auth', 'signIn']
    for pat in pats:
        idx = text.find(pat)
        if idx != -1:
            start = max(0, idx - 80)
            end = min(len(text), idx + 80)
            print('---', pat, '---')
            print(text[start:end].replace('\n', '\\n'))

if __name__ == '__main__':
    find_keywords()
