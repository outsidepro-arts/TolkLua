--[[
TolkLua - Tolk wrapper for Lua through Alien
Tolk library written by Davy Kager (Copyright:      (c) 2014-2016, Davy Kager <mail@davykager.nl>)
Tolk library license: LGPLv3
Wrapper written by Denis Shishkin (Copyright:      (c) 2021, Outsidepro Arts  <denis.outsidepro@gmail.com>)
This wrapper requires the Alien library
https://github.com/mascarenhas/alien
The content of Tolk library must have placed at the root of the Lua project. If you need to place the content  at another directory just change the path to you need.
All methods are presented in needed type so you can wait the boolean types in cases where is.
I wrote this wrapper using Lua 5.3, but you can try to another versions of Lua interpreter. Here is no specific operands used, so I think it mus be runnen without any fixes. But I'm not sure.
Please note that this wrapper can use already loaded Alien library, so you don't need to worry about superfluous Alien copies loading.
I will comment every function using official Tolk header comments
]]--

-- Metatable for converting any value to int
local toint = setmetatable({[false]=0, [true]=1},
{__index = function(self, value)
if tonumber(value) then
return tonumber(value)
-- IUP compatibility
elseif value:lower() == "on" or value:lower() == "off" then
return ({["on"]=1, ["off"]=0})[value:lower()]
else
error(string.format("toint error: expected any value which covertable to integer (boolean, number or string with digits or IUP states value, got value %s).", value))
return nil
end
end
})

-- Let check any alien library copy
local alien = nil
if package.loaded.alien then
alien = package.loaded.alien
elseif package.loaded.alien_c then
-- This is non-wrapped alien library. We freely can use this because we don't use any specific functions from
alien = package.loaded.alien_c
else
alien = require "alien_c"
end

-- Two WinAPI functions from kernel32
-- We need this because Tolk library processes wchar-t type
local wkernel = alien.load("kernel32")
wkernel.WideCharToMultiByte:types(
"int",
"uint",
"ulong",
"pointer",
"int",
"pointer",
"int",
"pointer",
"pointer"
)
wkernel.MultiByteToWideChar:types(
"int",
"uint",
"ulong",
"string",
"int",
"pointer",
"int"
) 

local tolkdll = alien.load("tolk.dll")
local Tolk = {}

 --  Name:         Tolk_Load
 --  Description:  Initializes Tolk by loading and initializing the screen reader drivers and setting the current screen reader driver, provided at least one of the supported screen readers is active. Also initializes COM if it has not already been initialized on the calling thread. Calling this function more than once will only initialize COM. You should call this function before using the functions below, though for convenience it is valid to call them at any time. Use the return value or Tolk_IsLoaded to determine whether or not Tolk has been initialized. This function does not return a value, as a screen reader driver failing to load is interpreted as that screen reader being unavailable.
 --  Parameters:   None.
 --  Returns:      None.
tolkdll.Tolk_Load:types("void")
Tolk.Load = tolkdll.Tolk_Load

--  Name:         Tolk_IsLoaded
 --  Description:  Tests if Tolk has been initialized. You should initialize Tolk by calling Tolk_Load before using the functions below, though for convenience it is valid to call them at any time.
 --  Parameters:   None.
--  Returns:      true if Tolk has been initialized, false otherwise.
tolkdll.Tolk_IsLoaded:types("int")
function Tolk.IsLoaded() return (tolkdll.Tolk_IsLoaded() == 1) end

--  Name:         Tolk_Unload
--  Description:  Finalizes Tolk by finalizing and unloading the screen reader drivers and clearing the current screen reader driver, provided one was set. Also uninitializes COM on the calling thread. Calling this function more than once will only uninitialize COM. You should not use the functions below if this function has been called, though for convenience it is valid to call them at any time.
--  Parameters:   None.
--  Returns:      None.
tolkdll.Tolk_Unload:types("void")
Tolk.Unload = tolkdll.Tolk_Unload

--  Name:         Tolk_TrySAPI
--  Description:  Sets if Microsoft Speech API (SAPI) should be used in the screen reader auto-detection process. The default is not to include SAPI. The SAPI driver will use the system default synthesizer, voice and soundcard. This function triggers the screen reader detection process if needed. For best performance, you can bypass the extra screen reader detection round by calling this function before calling Tolk_Load, but to support dynamic changes it can be called at any time.
--  Parameters:   trySAPI: whether or not to include SAPI in auto-detection.
--  Returns:      None.
tolkdll.Tolk_TrySAPI:types("void", "int")
function Tolk.TrySAPI(trySAPI)
if trySAPI == nil then error("The trySAPI must be passed.") end
 return (tolkdll.Tolk_TrySAPI(toint[trySAPI]) == 1)
end

--  Name:         Tolk_PreferSAPI
--  Description:  If auto-detection for SAPI has been turned on through Tolk_TrySAPI, sets if SAPI should be placed first (true) or last (false) in the screen reader detection list. Putting it last is the default and is good for using SAPI as a fallback option. Putting it first is good for ensuring SAPI is used even when a screen reader is running, but keep in mind screen readers will still be tried if SAPI is unavailable. This function triggers the screen reader detection process if needed. For best performance, you can bypass the extra screen reader detection round by calling this function before calling Tolk_Load, but to support dynamic changes it can be called at any time.
--  Parameters:   preferSAPI: whether or not to prefer SAPI over screen reader drivers in auto-detection.
--  Returns:      None.
tolkdll.Tolk_PreferSAPI:types("void", "int")
function Tolk.PreferSAPI(preferSAPI)
if preferSAPI == nil then error("The preferSAPI must be passed.") end
return (tolkdll.Tolk_PreferSAPI(toint[preferSAPI]) == 1)
end

--  Name:         Tolk_DetectScreenReader
--  Description:  Returns the common name for the currently active screen reader driver, if one is set. If none is set, tries to detect the currently active screen reader before looking up the name. If no screen reader is active, NULL is returned. Note that the drivers hard-code the common name, it is not requested from the screen reader itself. You should call Tolk_Load once before using this function, though for convenience it can be called at any time.
--  Parameters:   None.
--  Returns:      A  string representation of the common name on success, NULL otherwise.
tolkdll.Tolk_DetectScreenReader:types("pointer")
function Tolk.DetectScreenReader()
local ret = tolkdll.Tolk_DetectScreenReader()
local presize = wkernel.WideCharToMultiByte(65001, 0, ret, -1, nil, 0, nil, nil)
if presize == 0 then return nil end
local buf = alien.buffer(presize)
local bufsize = wkernel.WideCharToMultiByte(65001, 0, ret, -1, buf:topointer(), presize, nil, nil)
local result = buf:tostring(bufsize-1)
buf = nil
return result
end

--  Name:         Tolk_HasSpeech
--  Description:  Tests if the current screen reader driver supports speech output, if one is set. If none is set, tries to detect the currently active screen reader before testing for speech support. You should call Tolk_Load once before using this function, though for convenience it can be called at any time.
--  Parameters:   None.
--  Returns:      true if the current screen reader driver supports speech, false otherwise.
tolkdll.Tolk_HasSpeech:types("int")
function Tolk.HasSpeech() return (tolkdll.Tolk_HasSpeech() == 1) end

--  Name:         Tolk_HasBraille
--  Description:  Tests if the current screen reader driver supports braille output, if one is set. If none is set, tries to detect the currently active screen reader before testing for braille support. You should call Tolk_Load once before using this function, though for convenience it can be called at any time.
--  Parameters:   None.
--  Returns:      true if the current screen reader driver supports braille, false otherwise.
tolkdll.Tolk_HasBraille:types("int")
function Tolk.HasBraille() return (tolkdll.Tolk_HasBraille() == 1) end

--  Name:         Tolk_Output
--  Description:  Outputs text through the current screen reader driver, if one is set. If none is set or if it encountered an error, tries to detect the currently active screen reader before outputting the given text. This is the preferred function to use for sending text to a screen reader, because it uses all of the supported output methods (i.e. speech and/or braille depending on the current screen reader driver). You should call Tolk_Load once before using this function, though for convenience it can be called at any time. This function is asynchronous.
--  Parameters:   str: text to output.
--                interrupt: optional; whether or not to first cancel any previous speech.
--  Returns:      true on success, false otherwise.
tolkdll.Tolk_Output:types("int", "pointer", "int")
function Tolk.Output(str, interrupt)
if str == nil then error("The str must be passed.") end
interrupt = interrupt or false
local presize = wkernel.MultiByteToWideChar(65001, 0, str, -1, NULL, 0)
local buf = alien.buffer(presize)
local bufsize = wkernel.MultiByteToWideChar(65001, 0, str, -1, buf:topointer(), presize)
local result = (tolkdll.Tolk_Output(buf:topointer(), toint[interrupt]) == 1)
buf = nil
return result
end

--  Name:         Tolk_Speak
--  Description:  Speaks text through the current screen reader driver, if one is set and supports speech output. If none is set or if it encountered an error, tries to detect the currently active screen reader before speaking the given text. Use this function only if you specifically need to speak text through the current screen reader driver without also brailling it. Not all screen reader drivers may support this functionality. Therefore, use Tolk_Output whenever possible, because it uses all of the supported output methods (i.e. speech and/or braille depending on the current screen reader driver). You should call Tolk_Load once before using this function, though for convenience it can be called at any time. This function is asynchronous.
--  Parameters:   str: text to speak.
--                interrupt: optional; whether or not to first cancel any previous speech.
--  Returns:      true on success, false otherwise.
tolkdll.Tolk_Speak:types("int", "pointer", "int")
function Tolk.Speak(str, interrupt)
if str == nil then error("The str must be passed.") end
interrupt = interrupt or false
local presize = wkernel.MultiByteToWideChar(65001, 0, str, -1, NULL, 0)
local buf = alien.buffer(presize)
local bufsize = wkernel.MultiByteToWideChar(65001, 0, str, -1, buf:topointer(), presize)
local result = (tolkdll.Tolk_Speak(buf:topointer(), toint[interrupt]) == 1)
buf = nil
return result
end

--  Name:         Tolk_Braille
--  Description:  Brailles text through the current screen reader driver, if one is set and supports braille output. If none is set or if it encountered an error, tries to detect the currently active screen reader before brailling the given text. Use this function only if you specifically need to braille text through the current screen reader driver without also speaking it. Not all screen reader drivers may support this functionality. Therefore, use Tolk_Output whenever possible, because it uses all of the supported output methods (i.e. speech and/or braille depending on the current screen reader driver). You should call Tolk_Load once before using this function, though for convenience it can be called at any time.
--  Parameters:   str: text to braille.
--  Returns:      true on success, false otherwise.
tolkdll.Tolk_Braille:types("int", "pointer")
function Tolk.Braille(str)
if str == nil then error("The str must be passed.") end
local presize = wkernel.MultiByteToWideChar(65001, 0, str, -1, NULL, 0)
local buf = alien.buffer(presize)
local bufsize = wkernel.MultiByteToWideChar(65001, 0, str, -1, buf:topointer(), presize)
local result = (tolkdll.Tolk_Braille(buf:topointer()) == 1)
buf = nil
return result
end

--  Name:         Tolk_IsSpeaking
--  Description:  Tests if the screen reader associated with the current screen reader driver is speaking, if one is set and supports querying for status information. If none is set, tries to detect the currently active screen reader before testing if it is speaking. You should call Tolk_Load once before using this function, though for convenience it can be called at any time.
--  Parameters:   None.
--  Returns:      true if text is being spoken by the screen reader, false otherwise.
tolkdll.Tolk_IsSpeaking:types("int")
function Tolk.IsSpeaking() return (tolkdll.Tolk_IsSpeaking() == 1) end

--  Name:         Tolk_Silence
--  Description:  Silences the current screen reader's speech, if the current screen reader driver is set and supports speech output. If none is set or if it encountered an error, tries to detect the currently active screen reader before silencing speech. Silencing speech only clears any queued text, it does not permanently disable speech (i.e. any future calls to Tolk_Output or Tolk_Speak will still work). You should call Tolk_Load once before using this function, though for convenience it can be called at any time.
--  Parameters:   None.
--  Returns:      true on success, false otherwise.
tolkdll.Tolk_Silence:types("int")
function Tolk.Silence() return (tolkdll.Tolk_Silence() == 1) end

-- Let make Tolk table more friendly
-- You will be able to call raw Tolk dll functions if needed. There are already asigned any type for each of.
Tolk.raw = tolkdll


return Tolk