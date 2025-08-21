import React, {useEffect, useState} from "react";
import axios from "axios";

export default function App(){
  const [info, setInfo] = useState(null);
  useEffect(()=>{ axios.get('/api/info').then(r=>setInfo(r.data)).catch(()=>{}) },[]);
  return (
    <div style={{fontFamily:'system-ui, Arial, sans-serif', padding:24}}>
      <h1>IntelliSec</h1>
      <p>AI-driven Security Platform — demo frontend</p>
      <pre>{info ? JSON.stringify(info, null, 2) : 'Loading...'}</pre>
    </div>
  )
}
