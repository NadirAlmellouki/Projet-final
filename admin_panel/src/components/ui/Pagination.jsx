import Button from "./Button";
import "./ui.css";
export default function Pagination({ page, totalPages, total, onPageChange }) {
  if (totalPages <= 1) return null;
  return (
    <div className="pagination">
      <span className="pagination__info">Page {page} sur {totalPages} · {total} résultat{total !== 1 ? "s" : ""}</span>
      <div className="pagination__controls">
        <Button variant="secondary" size="sm" disabled={page <= 1} onClick={() => onPageChange(page - 1)}>Précédent</Button>
        <Button variant="secondary" size="sm" disabled={page >= totalPages} onClick={() => onPageChange(page + 1)}>Suivant</Button>
      </div>
    </div>
  );
}
