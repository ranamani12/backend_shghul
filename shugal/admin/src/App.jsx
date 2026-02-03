import './App.css'
import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom'
import Layout from './components/Layout'
import ProtectedRoute from './components/ProtectedRoute'
import Login from './pages/Login'
import Dashboard from './pages/Dashboard'
import Candidates from './pages/Candidates'
import CandidateProfile from './pages/CandidateProfile'
import Companies from './pages/Companies'
import CompanyProfile from './pages/CompanyProfile'
import Jobs from './pages/Jobs'
import JobDetail from './pages/JobDetail'
import Countries from './pages/Countries'
import Lookups from './pages/Lookups'
import Transactions from './pages/Transactions'
import ActivityLogs from './pages/ActivityLogs'
import Settings from './pages/Settings'
import ResumeQuestions from './pages/ResumeQuestions'
import DeletionRequests from './pages/DeletionRequests'

function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/login" element={<Login />} />
        <Route
          path="/"
          element={
            <ProtectedRoute>
              <Layout />
            </ProtectedRoute>
          }
        >
          <Route index element={<Dashboard />} />
          <Route path="candidates" element={<Candidates />} />
          <Route path="candidates/:id" element={<CandidateProfile />} />
          <Route path="companies" element={<Companies />} />
          <Route path="companies/:id" element={<CompanyProfile />} />
          <Route path="jobs" element={<Jobs />} />
          <Route path="jobs/:id" element={<JobDetail />} />
          <Route path="countries" element={<Countries />} />
          <Route path="lookups" element={<Lookups />} />
          <Route path="transactions" element={<Transactions />} />
          <Route path="activity-logs" element={<ActivityLogs />} />
          <Route path="settings" element={<Settings />} />
          <Route path="resume-questions" element={<ResumeQuestions />} />
          <Route path="deletion-requests" element={<DeletionRequests />} />
        </Route>
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </BrowserRouter>
  )
}

export default App
