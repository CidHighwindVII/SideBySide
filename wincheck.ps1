Add-Type @"
using System;using System.Text;using System.Runtime.InteropServices;using System.Collections.Generic;
public class W{
 public struct RECT{public int L,T,R,B;}
 delegate bool EnumProc(IntPtr, IntPtr);
 [DllImport("user32.dll")] static extern bool EnumWindows(EnumProc cb, IntPtr l);
 [DllImport("user32.dll")] static extern int GetWindowTextW(IntPtr h, StringBuilder s, int n);
 [DllImport("user32.dll")] static extern bool IsWindowVisible(IntPtr h);
 [DllImport("user32.dll")] static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
 [DllImport("user32.dll")] static extern bool GetWindowRect(IntPtr h, out RECT r);
 delegate bool EnumProc(IntPtr, IntPtr);
 public struct RECT{public int L,T,R,B;}
 public static List<string> Find(uint target){var o=new List<string>();EnumWindows((h,l)=>{uint pid;GetWindowThreadProcessId(h,out pid);if(pid==target){var sb=new StringBuilder(256);GetWindowTextW(h,sb,256);RECT r;GetWindowRect(h,out r);o.Add(string.Format("hwnd={0} vis={1} title=[{2}] rect={3},{4},{5},{6}",h,IsWindowVisible(h),sb,r.L,r.T,r.R,r.B));}return true;},IntPtr.Zero);return o;}
}
"@
$p = Get-Process sidebyside -ErrorAction SilentlyContinue
if ($p) { [W]::Find([uint32]$p.Id) } else { "no process" }
